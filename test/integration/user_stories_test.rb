require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :products

  test "buying a product" do
  LineItem.delete_all
  Order.delete_all
  ruby_book = products(:ruby)

  #A user goes to the store index
  get "/"
  assert_response :success
  assert_template "index"

  #They select a product, adding it to their cart
  xml_http_request :post, '/line_items', product_id: ruby_book.id
  assert_response :success

  cart = Cart.find(session[:cart_id])
  assert_equal 1, cart.line_items.size
  assert_equal ruby_book, cart.line_items[0].product

  #They then check out
  get "/orders/new"
  assert_response :success
  assert_template "new"

  #posting the form data to the save_order action
  post_via_redirect "/orders",
                    order: { name:     "Dave Thomas",
                             address:  "123 The Street",
                             email:    "dave@example.com",
                             pay_type: "Check" }
  assert_response :success

  #Verifying we’ve been redirected to the index.
  assert_template "index"

  #Check that cart is empty
  cart = Cart.find(session[:cart_id])
  assert_equal 0, cart.line_items.size

  #Go to database and verify that the order was created
  orders = Order.all
  assert_equal 1, orders.size
  order = orders[0]

  #check that details of order are correct
  assert_equal "Dave Thomas",      order.name
  assert_equal "123 The Street",   order.address
  assert_equal "dave@example.com", order.email
  assert_equal "Check",            order.pay_type

  #check that corresponding line item exists
  assert_equal 1, order.line_items.size
  line_item = order.line_items[0]
  assert_equal ruby_book, line_item.product

  #Verify that mail is correctly addressed and has expected subject line
  mail = ActionMailer::Base.deliveries.last
  assert_equal ["dave@example.com"], mail.to
  assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
  assert_equal "Pragmatic Store Order Confirmation", mail.subject

  end
end
