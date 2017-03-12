class EventTracker::Integration::GoogleAnalytics < EventTracker::Integration::Base
  def init
    <<-EOD
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

      ga('create', '#{@key}', 'auto', {'name': 'event_tracker'});
      ga('event_tracker.send', 'pageview');
      ga('event_tracker.require', 'ecommerce');
    EOD
  end

  def track(event_name, properties = {})
    %Q{ga('event_tracker.send', 'event', 'event_tracker', '#{event_name}');}
  end

  def add_transaction(id, affiliation, revenue, shipping, tax)
    if tax
      %Q[ga('event_tracker.ecommerce:addTransaction', { 'id': '#{id}', 'affiliation': '#{affiliation}', 'revenue': '#{revenue}', 'shipping': '#{shipping}', 'tax': '#{tax}' });]
    elsif shipping
      %Q[ga('event_tracker.ecommerce:addTransaction', { 'id': '#{id}', 'affiliation': '#{affiliation}', 'revenue': '#{revenue}', 'shipping': '#{shipping}' });]
    elsif revenue
      %Q[ga('event_tracker.ecommerce:addTransaction', { 'id': '#{id}', 'affiliation': '#{affiliation}', 'revenue': '#{revenue}' });]
    else
      %Q[ga('event_tracker.ecommerce:addTransaction', { 'id': '#{id}', 'affiliation': '#{affiliation}' });]
    end
  end

  def add_item(id, name, sku, category, price, quantity)
    if quantity
      %Q[ga('event_tracker.ecommerce:addItem', { 'id': '#{id}', 'name': '#{name}', 'sku': '#{sku}', 'category': '#{category}', 'price': '#{price}', 'quantity': '#{quantity}' });]
    elsif price
      %Q[ga('event_tracker.ecommerce:addItem', { 'id': '#{id}', 'name': '#{name}', 'sku': '#{sku}', 'category': '#{category}', 'price': '#{price}' });]
    elsif category
      %Q[ga('event_tracker.ecommerce:addItem', { 'id': '#{id}', 'name': '#{name}', 'sku': '#{sku}', 'category': '#{category}' });]
    elsif sku
      %Q[ga('event_tracker.ecommerce:addItem', { 'id': '#{id}', 'name': '#{name}', 'sku': '#{sku}' });]
    end
  end
end
