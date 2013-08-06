#-*- encoding: utf-8 -*-
require 'open-uri'
require 'rexml/document'

module Dmm
  module Configuration
    def initialize(api_id=nil,affiliate_id=nil)
      @url = 'http://affiliate-api.dmm.com/'
      @api = api_id.nil? ? ENV['DMM_API_ID'] : api_id
      @id = affiliate_id.nil? ? ENV['DMM_AFFILIATE_ID'] : affiliate_id
      @version = '2.00'
      site
      puts "API_ID= #{ENV['DMM_API_ID']}"
      puts "AFFILIATE_ID= #{ENV['DMM_AFFILIATE_ID']}"
    end
  end
end
module Dmm
  module Util
    #### Search
    # 検索
    # @param [String] word 検索キーワード
    # @return [Hash] APIのレスポンスをXML形式からHash形式に変更したもの
    def keyword(word, service: nil, floor: nil, hits: 20, offset: 1, sort: 'date')
      uri = create_uri(word, service:service, floor:floor, hits:hits , offset:offset, sort:sort)
      @keyword = word
      xmlbody = get_api(uri)
      # EUC-JPのまま通過
      # Railsだとなぜか自動的にUTF-8にしている気が。。
      xmlbody_enc = (xmlbody.encoding.to_s == "EUC-JP" ? xmlbody : xmlbody.encode("EUC-JP","UTF-8"))
      @xmldoc = REXML::Document.new(xmlbody_enc)
      @hashdoc = from_xml(@xmldoc)
      @hashdoc
    end
    
    def what_keyword
      @keyword
    end

    #### Hash Analyze
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Hash] requestの下を返す
    def get_request(h = nil)
      h ||= @hashdoc
      h[:response][:request]
    end
    
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Hash] requestの下を返す
    def get_result(h = nil)
      h ||= @hashdoc
      h[:response][:result]
    end
    
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Hash] requestの下を返す
    def get_items(h = nil)
      h ||= @hashdoc
      h[:response][:result][:items][:item]
    end
    
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Array] titleを返す
    def get_titles(h = nil)
      h ||= @hashdoc
      items = get_items(h)
      arr = []
      items.each do |m|
        arr << { :title => m[:title], :affiliate_id => m[:affiliate_id] }
      end
      arr
    end
    
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Array] 複数のimageとそのTitleを返す
    #  arr [ {:title => "", :images => ["url"]},...] 
    def get_title_images(h = nil)
      h ||= @hashdoc
      arr = []
      items = get_items(h)
      items.each do |m|
        arr << { :title => m[:title], :affiliate_id => m[:affiliate_id], :list => m[:imageURL][:list], :small => m[:imageURL][:small], :large => m[:imageURL][:large] }
      end
      arr
    end
    
    # @param [Hash] h DMMAPIのHash化したもの。
    #  nil ok
    # @return [Array] 複数のimageとそのTitleを返す
    #  arr [ {:title => "", :images => ["url"]},...] 
    def get_sample_images(h = nil)
      h ||= @hashdoc
      arr = []
      if h.nil?
        return no_image(1)
      end
      if get_result_count(h) == "0"
        return no_image(2)
      end
      items = get_items(h)
      items.each do |m|
        #Valid
        if m[:sampleImageURL].nil?
          next
        end
        if m[:sampleImageURL][:sample_s].nil?
          next
        end
        if m[:sampleImageURL][:sample_s][:image].nil?
          next
        end
        # あった
        arr << { 
          :title => m[:title], 
          :affiliateURL => m[:affiliateURL], 
          :images => m[:sampleImageURL][:sample_s][:image]
        }
      end
      if arr.empty?
        arr << no_image(3)
      end
      arr
    end

    def get_result_count(h=nil)
      h ||= @hashdoc
      h[:response][:result][:result_count]
    end

    #util_valid
    def no_image(i)
      err_str = case i 
      when 1
        "検索してないよ"
      when 2
        "検索結果は0件"
      when 3
        "すまない。sample_imageはないんだ(´・ω・｀)"
      else
        "no_imageは直接呼び出さないでくれ"
      end

        hash = { 
          :title => 'I do not have an image', 
          :affiliateURL => 'http://www.dmm.com/top/#{@id}-001', 
          :images => 'http://pics.dmm.com/af/c_top/125_125.jpg',
          :err => err_str
        }
        hash
    end

    #util
    def create_uri(word, service: nil, floor: nil, hits: 1, offset: 1, sort: 'rank')
      arr = []
      arr << "api_id=#{@api}"
      arr << "affiliate_id=#{@id}-991"
      arr << "operation=ItemList"
      arr << "version=#{@version}"
      arr << "timestamp=#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      arr << "site=#{@site}"
      arr << "keyword=#{word}"
      arr << "service=#{service}" if service 
      arr << "floor=#{floor}" if floor
      arr << "hits=#{hits}" if hits
      arr << "offset=#{offset}" if offset
      arr << "sort=#{sort}" if sort
      encode_uri = ("#{@url}?#{arr.join('&')}").encode("EUC-JP","UTF-8")
      URI.escape(encode_uri)
    end

    def get_api(uri)
      xml = ""
      open(uri) do |o|
        o.each do |l|
          if /\<parameter\sname/ =~ l
            # なんでParameterの中に入れるんだろうね(´・ω・｀)
            # 取り出そうよ
            b = l.scan(/\"(.*?)\"/).flatten
            xml << "<#{b[0]}>"
            xml << "#{b[1]}"
            xml << "</#{b[0]}>"
            xml << "\n"
          else
            xml << l
          end
        end

      end
      xml
    end

    #rexml
    def from_xml(rexml)
      xml_elem_to_hash rexml.root
    end
    
    private
    def xml_elem_to_hash(elem)
      value = if elem.has_elements?
        children = {}
        elem.each_element do |e|
          children.merge!(xml_elem_to_hash(e)) do |k,v1,v2|
            v1.class == Array ?  v1 << v2 : [v1,v2]
          end
        end
        children
      else
        elem.text
      end
      { elem.name.to_sym => value }
    end
  end
end

module Dmm
  class R18
    def site
      @site = "DMM.co.jp"
    end
    include Dmm::Configuration
    include Dmm::Util
  end
end

module Dmm
  class Com
    def site
      @site = "DMM.com"
    end
    include Dmm::Configuration
    include Dmm::Util
  end
end
