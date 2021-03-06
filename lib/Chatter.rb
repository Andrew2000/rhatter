require 'rubygems'
require 'httparty'
require 'Post'

class Chatter
  include HTTParty
  #doesn't seem to pick up env variable correctly if I set it here
  #headers 'Authorization' => "OAuth #{ENV['sfdc_token']}"
  format :json
  #debug_output $stderr
  #debug_output $stdout

  def self.set_headers
    headers 'Authorization' => "OAuth #{ENV['sfdc_token']}"
  end

  def self.root_url
    @root_url = ENV['sfdc_instance_url']+"/services/data/v"+ENV['sfdc_api_version']+"/chatter"
  end
  


  def self.get_users_info(id)
    Chatter.set_headers
    @resp = get(Chatter.root_url+"/users/"+id)
    Chatter.log_response(@resp, "get_user_info")
    return @resp
  end

  def self.get_my_info
    
    Chatter.get_users_info("me")
  end
  
  def self.get_newsfeed(id)
    Chatter.set_headers
    @resp = get(Chatter.root_url+"/feeds/news/"+id+"/feed-items")
    Chatter.log_response(@resp, "get_newsfeed")
    return @resp
  end
    
  def self.get_my_newsfeed
    Chatter.get_newsfeed("me")
  end
  
  def self.set_my_user_status(post)
    options = Chatter.set_http_options
    
    options.merge!( :body => { :body => { :messageSegments => [
                                {
                                  :type => "Text",
                                  :text => post.body
                                }
                              ]}
                             }.to_json
                    )
   puts "HELLO"
   puts @options
    @response = HTTParty.post(Chatter.root_url+"/feeds/news/me/feed-items", options)
    end
  
  def self.like_feeditem(id)
    post(Chatter.root_url+"/feed-items/"+id+"/likes")
  end
  
  def self.unlike_feeditem(id)
    delete(Chatter.root_url+"/feed-items/"+id+"/likes")
  end
  
  def self.add_comment(comment)
         options = Chatter.set_http_options

         options.merge!( :body => { :body => { :messageSegments => [
                                     {
                                       :type => "Text",
                                       :text => comment.body
                                     }
                                   ]}
                                  }.to_json
                         )

         @response = HTTParty.post(Chatter.root_url+"/feed-items/"+comment.feeditemid+"/comments", options)
         
  end
  
  
  #pre rel chatter page results returns the incorrect json response. it should be [feeditems][items]
  #like everything else, but it is just [items] so lets wrap it to make it consistent
  def self.get_page_of_feed(refpath)
    Chatter.set_headers
    
     @feed = Hash.new{}
      @feed["feedItems"] = Hash.new{} 
      
       @feed["feedItems"] = get(ENV['sfdc_instance_url']+refpath)
       return @feed
  end
  
  def self.set_http_options
    @options = { :headers => { 'Authorization'   => "OAuth #{ENV['sfdc_token']}",
                                   'Content-Type'    => "application/json",
                                   'X-PrettyPrint'   => "1"                       
                                 }
                   }
    return @options
  end
  
  def self.log_response(resp, method_name)
    CHATTER_LOGGER.debug("\n------START "+method_name+"---------\n")
    CHATTER_LOGGER.debug(resp)
    CHATTER_LOGGER.debug("\n------END "+method_name+"---------\n")
  end
end
