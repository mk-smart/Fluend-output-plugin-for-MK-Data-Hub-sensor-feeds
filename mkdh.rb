# Elementary fluentd output plugin to push data to an                                                                                                                                                                                   
# MK Data Hub sensor stream. Requires the id of the feed and                                                                                                                                                                            
# stream, the API key and the way to extract the value from the data                                                                                                                                                                    
# TODO:                                                                                                                                                                                                                                 
#    take date/time from attribute - but need to be either epoch or ISO                                                                                                                                                                 
module Fluent
  class MKDHS < BufferedOutput
    Fluent::Plugin.register_output('mkdhs', self)
    config_param :feedid,    :string # feedid                                                                                                                                                                                           
    config_param :streamid,  :string # streamid                                                                                                                                                                                         
    config_param :valueattr, :string # valueattr                                                                                                                                                                                        
    config_param :dhkey, :string     # apikey to use for upload                                                                                                                                                                         

    config_param :timestampattr, :string, :default => nil # which data attribute to use for the timestamp.                                                                                                                              
                                                          # Use fluentd timestamp if nil                                                                                                                                                
                                                          # NOT CURRENTLY SUPPORTED                                                                                                                                                     
    def configure(conf)
      super
      require 'msgpack'
      require 'net/http'
    end

    def start
      super
      @mkdhurl = "https://api.beta.mksmart.org/sensors/feeds/#{@feedid}/datastreams/#{@streamid}/datapoints"
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [time, record].to_msgpack
    end

    def write(chunk)
      eemls = '<?xml version="1.0" encoding="UTF-8"?> ' + "\n" +
	'<eeml xmlns="http://www.eeml.org/xsd/0.5.1" '+ "\n" +
	'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '+ "\n" +
	'version="0.5.1" '+ "\n" +
	'xsi:schemaLocation="http://www.eeml.org/xsd/0.5.1 http://www.eeml.org/xsd/0.5.1/0.5.1.xsd">'+ "\n" +
	'<environment><data id="'+@streamid+'"><current_value></current_value><datapoints>';
      chunk.msgpack_each {|(time,record)|
	tval = record[@valueattr] unless !record
	eemls = eemls+'<value at="'+DateTime.strptime(time.to_s, "%s").to_s+'">'+tval.to_s+'</value> ' + "\n";
      }
      eemls = eemls + '</datapoints></data></environment></eeml>'
      $log.info "Sending #{eemls}"
      uri = URI(@mkdhurl)
      https = Net::HTTP.new(uri.host,uri.port)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path)
      req.body = eemls
      req.basic_auth @dhkey, ''
      req['Content-Type'] = 'text/xml'
      req['Accept'] = '*/*'
      res = https.request(req)
      $log.info "received: " + res.code
      $log.info "        : " + res.message
      $log.info "        : " + res.body
    end
  end
end
