require "spec_helper"

shared_examples_for "init" do
  subject { page.find("head script", visible: false).native.content }
  it { should include('mixpanel.init("YOUR_TOKEN")') }
  it { should include(%q{var _kmk = _kmk || 'KISSMETRICS_KEY'}) }
  it { should include(%q{ga('create', 'GOOGLE_ANALYTICS_KEY', 'auto', {'name': 'event_tracker'});}) }
  it { should include('analytics.load("SEGMENT_KEY")') }
end

shared_examples_for "without distinct id" do
  it { should_not include(%q{_kmq.push(['identify', 'name@email.com']);}) }
  it { should_not include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "with distinct id" do
  it { should include(%q{_kmq.push(['identify', 'name@email.com']);}) }
  it { should include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "without event" do
  it { should_not include('mixpanel.track("Register for site")') }
  it { should_not include(%q{ga('event_tracker.send', 'event', 'event_tracker', 'Register for site');}) }
end

shared_examples_for "with event" do
  it { should include('mixpanel.track("Register for site")') }
  it { should include(%q{_kmq.push(['record', 'Register for site']);}) }
  it { should include(%q{ga('event_tracker.send', 'event', 'event_tracker', 'Register for site');}) }
end

feature 'basic integration' do
  subject { page.find("body script", visible: false).native.content }

  class BasicController < ApplicationController
    around_action :append_event_tracking_tags
    def no_tracking
      render inline: "OK", layout: true
    end

    def with_tracking
      track_event "Register for site"
      render inline: "OK", layout: true
    end
  end

  context 'visit page without tracking' do
    background { visit '/basic/no_tracking' }
    it_should_behave_like "init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "without event"
  end

  context 'visit page with tracking' do
    background { visit '/basic/with_tracking' }
    it_should_behave_like "init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "with event"
  end

  context 'visit page with tracking' do
    background { visit '/basic/in_views' }
    it_should_behave_like "with event"
  end

  context 'visit page with tracking then without tracking' do
    background do
      visit '/basic/with_tracking'
      visit '/basic/no_tracking'
    end
    it_should_behave_like "without event"
  end

  class RedirectsController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      track_event "Register for site"
      redirect_to action: :redirected
    end

    def redirected
      render inline: "OK", layout: true
    end
  end

  context 'track event then redirect' do
    background { visit '/redirects' }
    it_should_behave_like "with event"
  end

  class WithPropertiesController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      register_properties age: 19
      register_properties gender: "female"
      track_event "Take an action", property1: "a", property2: 1, xss: "</script>"
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/with_properties" }
    it { should include %q{mixpanel.track("Take an action", {"property1":"a","property2":1,"xss":"\u003c/script\u003e"})} }
    it { should include %Q{mixpanel.register({"age":19,"gender":"female"})} }
    it { should include %q{_kmq.push(['record', 'Take an action', {"property1":"a","property2":1,"xss":"\u003c/script\u003e"}])} }
    it { should include %Q{_kmq.push(['set', {"age":19,"gender":"female"}])} }
  end

  class IdentityController < ApplicationController
    around_action :append_event_tracking_tags
    def mixpanel_distinct_id
      "distinct_id"
    end

    def kissmetrics_identity
      "name@email.com"
    end

    def index
      render inline: "OK", layout: true
    end
  end

  context "with identity" do
    background { visit "/identity" }
    it_should_behave_like "with distinct id"
  end

  class NameTagController < ApplicationController
    around_action :append_event_tracking_tags
    def mixpanel_name_tag
      "foo@example.org"
    end

    def index
      render inline: "OK", layout: true
    end
  end

  context "with name tag" do
    background { visit "/name_tag" }
    it { should include(%q{mixpanel.name_tag("foo@example.org")}) }
  end

  class PrivateController < ApplicationController
    around_action :append_event_tracking_tags
    def index; render inline: "OK", layout: true; end
    private
    def mixpanel_distinct_id; "distinct_id"; end
    def kissmetrics_identity; "name@email.com"; end
  end

  context "with private methods" do
    background { visit "/private" }
    it_should_behave_like "with distinct id"
  end

  class SetConfigController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      mixpanel_set_config 'track_pageview' => false
      render inline: "OK", layout: true
    end
  end

  context 'configure mixpanel' do
    background { visit '/set_config' }
    it { should include %Q{mixpanel.set_config({"track_pageview":false})} }
  end

  class PeopleSetController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      mixpanel_people_set "$email" => "jsmith@example.com"
      render inline: "OK", layout: true
    end
  end

  context "people set properties" do
    background { visit "/people_set" }
    it { should include %Q{mixpanel.people.set({"$email":"jsmith@example.com"})} }
  end

  class PeopleSetOnceController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      mixpanel_people_set_once "One more time" => "With feeling"
      render inline: "OK", layout: true
    end
  end

  context 'people set properties once' do
    background { visit '/people_set_once' }
    it { should include %Q{mixpanel.people.set_once({"One more time":"With feeling"})} }
  end

  class PeopleIncrementController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      mixpanel_people_increment "Named Attribute"
      render inline: "OK", layout: true
    end
  end

  context 'people set properties once' do
    background { visit '/people_increment' }
    it { should include %Q{mixpanel.people.increment(["Named Attribute"])} }
  end

  class AliasController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      mixpanel_alias "jsmith@example.com"
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/alias" }
    it { should include %Q{mixpanel.alias("jsmith@example.com")} }
  end

  class BeforeFilterController < ApplicationController
    around_action :append_event_tracking_tags
    before_action :halt_the_chain_and_render

    def index
      render inline: "ORIGINAL", layout: true
    end

    def halt_the_chain_and_render
      render inline: "HALTED", layout: true
    end

  end

  context "halting filter chain in a before_action" do
    background { visit "/before_action" }
    it_should_behave_like "init"
    it { expect(page.body).to_not include("ORIGINAL") }
    it { expect(page.body).to include("HALTED") }
  end

  if Rails.version >= "5"
    class ApiController < ActionController::API
      def index
        head :ok
      end
    end

    background { visit "/api" }
    it { expect(page).to have_http_status(:ok) }
  end

  #
  # Segment Tests
  #
  class SegmentTrackController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_track 'Article Completed', title: 'How to Create a Tracking Plan', course: 'Intro to Analytics'
      render inline: "OK", layout: true
    end
  end

  context "segment_track" do
    background { visit "/segment_track" }
    it { should include %Q{analytics.track("Article Completed", {"title":"How to Create a Tracking Plan","course":"Intro to Analytics"})} }
  end

  class SegmentIdentify1Controller < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_identify nil, nickname: 'Amazing Grace', favoriteCompiler: 'A-0', industry: 'Computer Science'
      render inline: "OK", layout: true
    end
  end

  context "segment_identify without user_id" do
    background { visit "/segment_identify1" }
    it { should include %Q{analytics.identify({"nickname":"Amazing Grace","favoriteCompiler":"A-0","industry":"Computer Science"})} }
  end

  class SegmentIdentify2Controller < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_identify '12091906-01011992', name: 'Grace Hopper', email: 'grace@usnavy.gov'
      render inline: "OK", layout: true
    end
  end

  context "segment_identify with user_id" do
    background { visit "/segment_identify2" }
    it { should include %Q{analytics.identify("12091906-01011992", {"name":"Grace Hopper","email":"grace@usnavy.gov"})} }
  end

  class SegmentGroupController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_group 'UNIVAC Working Group', principles: ['Eckert', 'Mauchly'], site: 'Eckert–Mauchly Computer Corporation', statedGoals: 'Develop the first commercial computer', industry: 'Technology'
      render inline: "OK", layout: true
    end
  end

  context "segment group" do
    background { visit "/segment_group" }
    it { should include %Q{analytics.group("UNIVAC Working Group", {"principles":["Eckert","Mauchly"],"site":"Eckert–Mauchly Computer Corporation","statedGoals":"Develop the first commercial computer","industry":"Technology"});} }
  end

  class SegmentPage1Controller < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_page nil, 'Pricing'
      render inline: "OK", layout: true
    end
  end

  context "segment page0" do
    background { visit "/segment_page0" }
    it { should include %Q{analytics.page();} }
  end

  class SegmentPage0Controller < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_page
      render inline: "OK", layout: true
    end
  end

  context "segment page1" do
    background { visit "/segment_page1" }
    it { should include %Q{analytics.page("Pricing");} }
  end

  class SegmentPage2Controller < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_page nil, 'Pricing', {
          title: 'Segment Pricing',
          url: 'https://segment.com/pricing',
          path: '/pricing',
          referrer: 'https://segment.com/warehouses' }
      render inline: "OK", layout: true
    end
  end

  context "segment page2" do
    background { visit "/segment_page2" }
    it { should include %Q{analytics.page("Pricing", {"title":"Segment Pricing","url":"https://segment.com/pricing","path":"/pricing","referrer":"https://segment.com/warehouses"});} }
  end

  class SegmentGroupController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_group 'UNIVAC Working Group', {
          principles: ['Eckert', 'Mauchly'],
          site: 'Eckert–Mauchly Computer Corporation',
          statedGoals: 'Develop the first commercial computer',
          industry: 'Technology'
      }
      render inline: "OK", layout: true
    end
  end

  context "segment group" do
    background { visit "/segment_group" }
    it { should include %Q{analytics.group("UNIVAC Working Group", {"principles":["Eckert","Mauchly"],"site":"Eckert–Mauchly Computer Corporation","statedGoals":"Develop the first commercial computer","industry":"Technology"});} }
  end

  class SegmentAliasController < ApplicationController
    around_action :append_event_tracking_tags

    def index
      segment_alias "507f191e81"
      render inline: "OK", layout: true
    end
  end

  context "segment alias" do
    background { visit "/segment_alias" }
    it { should include %Q{analytics.alias("507f191e81");} }
  end
end
