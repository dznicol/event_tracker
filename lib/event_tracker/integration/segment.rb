class EventTracker::Integration::Segment < EventTracker::Integration::Base
  def init
    s = <<-EOD
      !function(){var analytics=window.analytics=window.analytics||[];if(!analytics.initialize)if(analytics.invoked)window.console&&console.error&&console.error("Segment snippet included twice.");else{analytics.invoked=!0;analytics.methods=["trackSubmit","trackClick","trackLink","trackForm","pageview","identify","reset","group","track","ready","alias","debug","page","once","off","on"];analytics.factory=function(t){return function(){var e=Array.prototype.slice.call(arguments);e.unshift(t);analytics.push(e);return analytics}};for(var t=0;t<analytics.methods.length;t++){var e=analytics.methods[t];analytics[e]=analytics.factory(e)}analytics.load=function(t){var e=document.createElement("script");e.type="text/javascript";e.async=!0;e.src=("https:"===document.location.protocol?"https://":"http://")+"cdn.segment.com/analytics.js/v1/"+t+"/analytics.min.js";var n=document.getElementsByTagName("script")[0];n.parentNode.insertBefore(e,n)};analytics.SNIPPET_VERSION="4.0.0";
      analytics.load("#{@key}");
      analytics.page();
      }}();
    EOD
  end

  def track(event, options={})
    func(:track, event, options)
  end

  def identify(user_id, options={})
    func(:identify, user_id, options)
  end

  def group(group_id, options={})
    func(:group, group_id, options)
  end

  def page(category=nil, name=nil, properties={}, options={})
    params = ''
    params += %Q{"#{category}", } if category.present?
    params += %Q{"#{name}"} if name.present?
    params += %Q{, #{embeddable_json(properties)}} if properties.present?
    params += %Q{, #{embeddable_json(options)}} if options.present?

    params.present? ? %Q{analytics.page(#{params});} : %Q{analytics.page();}
  end

  def alias(user_id, options={})
    func(:alias, user_id, options)
  end

  def flush()
    %Q{analytics.flush();}
  end

  private
  def func(m, arg1, options)
    integrations = {}
    if Rails.application.config.event_tracker.segment_integrations.present?
      integrations = Rails.application.config.event_tracker.segment_integrations[m.to_sym]
    end

    integration_arg = integrations.present? ? ", #{embeddable_json(integrations)}" : ''

    if arg1.present?
      p = options.empty? ? '' : ", #{embeddable_json(options)}"
      %Q{analytics.#{m}("#{arg1}"#{p}#{integration_arg});}
    else
      %Q{analytics.#{m}(#{embeddable_json(options)}#{integration_arg});}
    end
  end
end
