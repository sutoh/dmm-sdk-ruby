#-*- encoding: utf-8 -*-
require 'open-uri'
require 'rexml/document'

module Dmm
  module Configuration
    def initialize(api_id=nil,affiliate_id=nil)
      @url = 'http://affiliate-api.dmm.com/'
      @api = api_id.nil? ? 'edu1FFKxWMqbHxf1fZFH' : api_id
      @id = affiliate_id.nil? ? 'penix' : affiliate_id
      @site = 'DMM.co.jp'
      @version = '2.00'
      puts 'initialize ok!!'
    end
  end
end

module Dmm
  class Com
    include Dmm::Configuration
    
    #### Search
    # 検索
    # @param [String] word 検索キーワード
    # @return [Hash] APIのレスポンスをXML形式からHash形式に変更したもの
    def keyword(word, options = {:service => nil, :floor => nil, :hits => 20, :offset => 1, :sort => 'rank'})
      uri = create_uri(word)
      xmlbody = get_api(uri)
      xmlbody.encoding
      @xmldoc = REXML::Document.new(xmlbody)
      @hashdoc = from_xml(@xmldoc)
      @hashdoc
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
      items.each do |i|
        arr << i[:title]
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
      titles = get_titles(h)
      items.each_with_index do |m, i|
        arr << { :title => titles[i], :list => m[:imageURL][:list], :small => m[:imageURL][:small], :large => m[:imageURL][:large] }
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
      items = get_items
      titles = get_titles(h)
      items.each_with_index do |m, i|
        arr << { :title => titles[i], :images => m[:sampleImageURL][:sample_s][:image]}
      end
      arr
    end

    #util
    def create_uri(word, options = {})
      arr = []
      arr << "api_id=#{@api}"
      arr << "affiliate_id=#{@id}-991"
      arr << "operation=ItemList"
      arr << "version=#{@version}"
      arr << "timestamp=#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      arr << "site=#{@site}"
      arr << "keyword=#{word}"
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
          else
            xml << l
          end
        end

      end
      xml.force_encoding("utf-8")
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
# d = Dmm::Com.new
# d.keyword 'aa'
