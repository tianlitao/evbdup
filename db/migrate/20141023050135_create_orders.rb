# -*- encoding : utf-8 -*-
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
        t.integer :rule_id               , :comment => "流程ID"
        t.string :rule_step              , :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
    	t.string :name                   , :comment => "名称", :null => false
    	t.string :sn                     , :comment => "凭证编号（验收单号）"
        t.string :contract_sn            , :comment => "合同编号"
    	t.string :buyer_name             , :comment => "采购单位名称"
        t.string :payer                  , :comment => "发票抬头"
        t.integer :buyer_id              , :comment => "采购单位ID"
    	t.string :buyer_code             , :comment => "采购单位real_ancestry"
        t.string :buyer_man              , :comment => "采购单位联系人"
        t.string :buyer_tel              , :comment => "采购单位联系人座机"
        t.string :buyer_mobile           , :comment => "采购单位联系人手机"
        t.string :buyer_addr             , :comment => "采购单位地址"
    	t.string :seller_name            , :comment => "供应商单位名称"
        t.integer :seller_id             , :comment => "供应商单位ID"
    	t.string :seller_code            , :comment => "供应商单位real_ancestry"
        t.string :seller_man             , :comment => "供应商单位联系人"
        t.string :seller_tel             , :comment => "供应商单位联系人座机"
        t.string :seller_mobile          , :comment => "供应商单位联系人手机"
        t.string :seller_addr            , :comment => "供应商单位地址"
        t.decimal :budget                , :comment => "总预算", :precision => 13, :scale => 2
    	t.decimal :total                 , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
    	t.date :deliver_at		         , :comment => "交付时间"
    	t.string :invoice_number         , :comment => "发票编号"
    	t.text :summary                  , :comment => "基本情况（备注）"
    	t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
    	t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
    	t.datetime :effective_time		 , :comment => "生效时间（统计）"
    	t.text :details                  , :comment => "明细"
    	t.text :logs                     , :comment => "日志"
      t.timestamps
    end
    add_index :orders, :sn, :unique => true
  end
end
