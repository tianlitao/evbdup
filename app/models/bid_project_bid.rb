# -*- encoding : utf-8 -*-
class BidProjectBid < ActiveRecord::Base
  belongs_to :bid_project
  has_many :items, class_name: "BidItemBid"
  has_many :uploads, as: :master

  def self.xml(who = '',options = {})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='供应商单位' column='com_name' class='required' display= "readonly" />
        <node name='供应商姓名' column='username' class='required' display= "readonly" />
        <node name='供应商电话' column='tel' />
        <node name='供应商手机' column='mobile' class='required' />
        <node name='供应商地址' class='add' class='required' />
        <node name='服务承诺' class='required' data_type='textarea'  />
        <node name='备注' class='required' data_type='textarea' />
      </root>
    }
  end
end
