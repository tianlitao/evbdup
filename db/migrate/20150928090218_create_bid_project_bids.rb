# -*- encoding : utf-8 -*-
# 网上竞价投标
class CreateBidProjectBids < ActiveRecord::Migration
  def change
    create_table :bid_project_bids do |t|
    	t.integer :bid_project_id
      t.string :com_name, :comment => "供应商单位"
      t.string :username, :comment => "供应商姓名"
      t.string :tel
      t.string :mobile
      t.string :emall
      t.string :add
      t.text :fwcn, :comment => "服务承诺"
      t.text :remark
      t.integer :user_id
      t.decimal :total, :comment => "总金额", :precision => 20, :scale => 2, :null => false, :default => 0
      t.text :logs

      t.timestamps
    end

    add_index :bid_project_bids, :bid_project_id
    add_index :bid_project_bids, :user_id


    create_table :bid_item_bids do |t|
    	t.integer :bid_project_id
    	t.integer :bid_item_id
    	t.string :brand_name
    	t.string :xh
    	t.integer :user_id
    	t.decimal :price, :comment => "单价", :precision => 20, :scale => 2, :null => false, :default => 0
    end

    add_index :bid_item_bids, :bid_project_id
    add_index :bid_item_bids, :bid_item_id

  end
end
