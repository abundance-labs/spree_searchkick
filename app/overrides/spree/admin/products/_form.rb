Deface::Override.new(
  virtual_path: 'spree/admin/products/_form',
  name: 'Add boost factor in product form',
  insert_bottom: '[data-hook=admin_product_form_promotionable]',
  text: <<-HTML
          <%= f.field_container :boost_factor, class: ['form-group'] do %>
            <%= f.label :boost_factor, Spree.t(:boost_factor) %>
            <%= f.select :boost_factor, (0..3).to_a, {}, class: 'form-control' %>
          <% end %>
  HTML
)
