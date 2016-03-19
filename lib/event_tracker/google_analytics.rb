class EventTracker::GoogleAnalytics
  def initialize(key)
    @key = key
  end

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
      %Q{ga('event_tracker.ecommerce:addTransaction', '#{id}', '#{affiliation}', '#{revenue}', '#{shipping}', '#{tax}');}
    elsif shipping
      %Q{ga('event_tracker.ecommerce:addTransaction', '#{id}', '#{affiliation}', '#{revenue}', '#{shipping}');}
    elsif revenue
      %Q{ga('event_tracker.ecommerce:addTransaction', '#{id}', '#{affiliation}', '#{revenue}');}
    else
      %Q{ga('event_tracker.ecommerce:addTransaction', '#{id}', '#{affiliation}');}
    end
  end

  def add_item(id, name, sku, category, price, quantity)
    if quantity
      %Q{ga('event_tracker.ecommerce:addItem', '#{id}', '#{name}', '#{sku}', '#{category}', '#{price}', '#{quantity}');}
    elsif price
      %Q{ga('event_tracker.ecommerce:addItem', '#{id}', '#{name}', '#{sku}', '#{category}', '#{price}');}
    elsif category
      %Q{ga('event_tracker.ecommerce:addItem', '#{id}', '#{name}', '#{sku}', '#{category}');}
    elsif sku
      %Q{ga('event_tracker.ecommerce:addItem', '#{id}', '#{name}', '#{sku}');}
    end
  end
end
