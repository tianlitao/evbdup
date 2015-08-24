# -*- encoding : utf-8 -*-
class Department < ActiveRecord::Base
	has_many :users, dependent: :destroy
  has_many :uploads, class_name: :DepartmentsUpload, foreign_key: :master_id
  # validates :name, presence: true, length: { in: 2..30 }, uniqueness: { case_sensitive: false }
  
  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Department") }, foreign_key: :obj_id

  include AboutAncestry
  include AboutStatus

  after_save do
    real_ancestry_arr = []
    real_ancestry_arr << self.ancestors.where(dep_type: false).map(&:id) if self.ancestors.present?
    real_ancestry_arr << self.id unless self.dep_type
    
    unless self.real_ancestry == real_ancestry_arr.join("/")
      self.real_ancestry = real_ancestry_arr.join("/") # 祖先和自己中是独立核算单位的id
      self.save 
    end
  end

  # 拆分real_ancestry 获取独立核算单位的id数组
  def real_ancestry_id_arr
    self.real_ancestry.split("/")
  end

  # 获取单位的第几层祖先 例如总公司(level = 2)还是分公司(level = 3) 没有返回nil
  def real_ancestry_level(level)
    return nil if self.real_ancestry_id_arr.length <= level - 1
    dep_id = self.real_ancestry_id_arr[0..level - 1].join("/")
    return Department.where(real_ancestry: dep_id)
  end

  # 发票单位 real_ancestry最后一位
  def real_dep
    dep_id = self.real_ancestry_id_arr.last
    return Department.find_by(id: dep_id)
  end

  # 独立核算单位下的所有用户
  def real_users
    users = []
    Department.where(real_ancestry: self.real_ancestry).each do |dep|
      dep.users.each do |user|
        users << user
      end
    end
    return users
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["未提交",0,"orange",10],
      ["正常",1,"u",100],
      ["等待审核",2,"blue",50],
      ["审核拒绝",3,"red",0],
      ["冻结",4,"yellow",20],
      ["已删除",404,"light",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "提交" => { "未提交" => "等待审核", "审核拒绝" => "等待审核" },
      "通过" => { "等待审核" => "正常" },
      "不通过" => { "等待审核" => "审核拒绝" },
      "删除" => { "未提交" => "已删除" },
      "冻结" => { "正常" => "冻结" },
      "恢复" => { "冻结" => "正常" }
    }
  end

  # 附件的类
  def self.upload_model
    DepartmentsUpload
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def self.purchaser
    Department.find_by(id: 2)
  end
  
  def self.supplier
    Department.find_by(id: 3)
  end

  # 根据单位的祖先节点判断单位是采购单位还是供应商
  def get_xml
    case self.try(:root_id)
    when Department.purchaser.try(:id) then Department.purchaser_xml
    when Department.supplier.try(:id) then Department.supplier_xml
    else Department.other_xml
    end
  end

  # 采购单位XML
  def self.purchaser_xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='单位名称' column='name' hint='必须与参照营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:3, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
        <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
        <node name='单位类型' column='dep_type' data_type='radio' data='[[0,"独立核算单位"],[1,"部门"]]' hint='独立核算单位是****************'/>
        <node name='邮政编码' column='post_code' rules='{required:true, number:true}'/>
        <node name='所在地区' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Area"}' partner='area_id'/>
        <node column='area_id' data_type='hidden'/>
        <node name='详细地址' column='address' class='required'/>
        <node name='电话（总机）' column='tel' class='required'/>
        <node name='传真' column='fax' class='required'/>
      </root>
    }
  end

  # 供应商XML
	def self.supplier_xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	      <node name='单位名称' column='name' hint='必须与参照营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:6, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
	      <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
        <node name='单位类型' column='dep_type' data_type='radio' data='[[0,"独立核算单位"],[1,"部门"]]' hint='独立核算单位是****************'/>
        <node name='营业执照注册号' column='license' hint='请参照营业执照上的注册号' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='税务登记证' column='tax' hint='请参照税务登记证上的号码' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='组织机构代码' column='org_code' hint='请参照组织机构代码证上的代码' rules='{required:true, minlength:10}' messages='请输入10个字符'/>
        <node name='单位法人姓名' column='legal_name' class='required'/>
        <node name='单位法人证件类型' class='required' data_type='radio' data='["居民身份证","驾驶证","护照"]'/>
        <node name='单位法人证件号码' column='legal_number' class='required'/>
        <node name='注册资金' column='capital' class='required'/>
        <node name='年营业额' column='turnover' class='required'/>
        <node name='单位人数' column='employee' data_type='radio' class='required' data='["20人以下","21-100人","101-500人","501-1001人","1001-10000人","1000人以上"]'/>
        <node name='邮政编码' column='post_code' rules='{required:true, number:true}'/>
	      <node name='所在地区' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Area"}' partner='area_id'/>
	      <node column='area_id' data_type='hidden'/>
        <node name='详细地址' column='address' class='required'/>
        <node name='公司网址' column='website'/>
        <node name='电话（总机）' column='tel' class='required'/>
        <node name='传真' column='fax' class='required'/>
	      <node name='单位介绍' column='summary' data_type='textarea' class='required' placeholder='不超过800字'/>
	    </root>
	  }
	end

  # 其他单位XML
  def self.other_xml(who='',options={})

  end

  # can_opt_arr = [:create, :read, :update] 对应cancancan验证的action 
	def cando_list(can_opt_arr=[],only_audit=false)
    return "" if can_opt_arr.blank?
		show_div = '#show_ztree_content #ztree_content'
    dialog = "#opt_dialog"
    arr = [] 
    # 查看单位信息
    arr << [self.class.icon_action("详细"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}', '#{show_div}')"] if can_opt_arr.include?(:read)
    # 提交
    arr << [self.class.icon_action("提交"), "/kobe/departments/#{self.id}/commit", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can_opt_arr.include?(:commit) && self.can_commit?
    if [0,1,3].include? self.status
      # 修改单位信息
      arr << [self.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/edit','#{show_div}')"] if can_opt_arr.include?(:update)
      # 修改资质证书
      arr << [self.class.icon_action("上传资质"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/upload','#{show_div}','edit_upload_fileupload')"] if can_opt_arr.include?(:upload)
      # 维护开户银行
      arr << [self.class.icon_action("维护开户银行"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/show_bank','#{show_div}')"] if can_opt_arr.include?(:bank)
      # 增加下属单位
      arr << [self.class.icon_action("增加下属单位"), "javascript:void(0)", onClick: "show_content('/kobe/departments/new?pid=#{self.id}','#{show_div}')"] if can_opt_arr.include?(:create)
      # 分配人员账号
      title = self.class.icon_action("增加人员")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/departments/#{self.id}/add_user', '#{dialog}') }] if can_opt_arr.include?(:add_user)
    end
    # 审核
    if self.status == 2
      audit_opt = [self.class.icon_action("审核"), "/kobe/departments/#{self.id}/audit"] if can_opt_arr.include?(:audit)
      return [audit_opt] if only_audit
      arr << audit_opt
    end
    return arr
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  def get_tips
    msg = []
    if [0].include?(self.status)
      msg << "单位信息填写不完整，请点击[修改]。" if self.area_id.blank?
      msg << "上传的资质证书不全，请点击[上传资质]。" if self.uploads.length < 4
      msg << "开户银行信息不完整，请点击[维护开户银行]" if self.bank.blank? || self.bank_code.blank?
      msg << "用户信息填写不完整，请在用户列表中点击[修改]。" if self.users.find{ |u| u.name.present? }.blank?
    end
    return msg
  end

  # 维护开户银行提示
  def bank_tips
    Dictionary.tips.bank
  end

  # 是否需要隐藏树形结构 用于没有下级单位的单位 不显示树
  def hide_tree?
    self.is_childless? || self.descendants.where.not(status: 404).blank?
  end

  # 是否可以提交
  def can_commit?
    self.get_tips.blank? && self.can_opt?("提交")
  end

  # 提交时需更新的参数 主要用于更新rule_id 
  # 返回 change_status_and_write_logs(opt,stateless_logs,update_params=[]) 的update_params 数组
  def commit_params
    arr = []
    rule_id = Rule.find_by(name: '单位管理').id
    arr << "rule_id = #{rule_id}"
    arr << "rule_step = 'start'"
    return arr
  end

end