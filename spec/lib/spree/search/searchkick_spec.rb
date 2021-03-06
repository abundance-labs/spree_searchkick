require 'spec_helper'
describe Spree::Search::Searchkick do
  let(:product) { create(:product) }

  before do
    product.reindex
    Spree::Product.reindex
  end

  describe '#retrieve_products' do
    context 'when search by keyword' do
      subject(:products) { Spree::Search::Searchkick.new(keywords: keywords).retrieve_products }

      let(:keywords) { product.name }

      it { expect(products.count).to eq(1) }

      context 'when product searchable by description' do
        let(:keywords) { product.description }

        before { allow(Spree::Product).to receive(:search_fields).and_return([:description]) }

        it { expect(products.count).to eq(1) }
      end
    end

    it 'returns matching products' do
      products = Spree::Search::Searchkick.new({}).retrieve_products
      expect(products.count).to eq 1
    end

    describe 'aggregations' do
      let(:taxonomy) { Spree::Taxonomy.where(id: 1, name: 'Category').first_or_create }

      before do
        product.taxons << taxonomy.root
        product.reindex
        Spree::Product.reindex
      end

      it 'has no aggregations by default' do
        products = Spree::Search::Searchkick.new({}).retrieve_products
        expect(products.aggs).to be_nil
      end

      context 'with a filterable taxonomy' do
        let(:taxonomy) { Spree::Taxonomy.where(id: 1, name: 'Category', filterable: true).first_or_create }

        it 'retrieves aggregations' do
          products = Spree::Search::Searchkick.new({}).retrieve_products

          expect(products.count).to eq 1
          expect(products.aggs['category_ids']).to include('doc_count' => 1)
          expect(products.aggs['category_ids']['buckets']).to be_a Array
        end
      end
    end

    describe 'boosting' do
      let!(:boost_product) { create :product, boost_factor: boost_factor }
      let(:keywords) { nil }

      subject do
        Spree::Product.reindex
        Spree::Search::Searchkick.new(keywords: keywords).retrieve_products.first
      end

      context 'when boost_factor is 0' do
        let(:boost_factor) { 0 }

        it { is_expected.to eq(product) }
      end

      context 'when boost_factor is 1' do
        let(:boost_factor) { 1 }

        it { is_expected.to eq(product) }
      end

      context 'when boost_factor is 2' do
        let(:boost_factor) { 2 }

        it { is_expected.to eq(boost_product) }
      end

      context 'when product has similar name' do
        let(:boost_factor) { 3 }
        let(:keywords) { 'why' }

        before do
          product.update(name: 'Why Why Why Did Dinosaurs Lay Eggs?')
          boost_product.update(name: 'Minefields & Miracles: Why God and Allah Need to Talk')
        end

        it { is_expected.to eq(boost_product) }
      end
    end
  end
end
