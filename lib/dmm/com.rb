require 'dmm/core'
require 'dmm/ec2/config'

module DMM
  class COM
    autoload :All, 'dmm/com/all' 
    autoload :AllCollection, 'dmm/com/all_collection' 
    autoload :Movie, 'dmm/com/movie'
    autoload :MonthlyMovie, 'dmm/com/monthly_movie'
    autoload :EBook, 'dmm/com/e_book'
    autoload :PcSoftware, 'dm/com/pc_software'
    autoload :MailOrder, 'dmm/com/mail_order'
    autoload :RentalDVD, 'dmm/com/rental_dvd'
    autoload :RentalVarious, 'dmm/com/rental_various'

    include Core::ServiceInterface
    
    endpoint_prefix 'com'
    
    # instance

    def alls
      AllCollection.new(:config => config)
    end
  end
end
