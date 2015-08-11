# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base
  # before_save {self.email = email.downcase}
  before_create :create_remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # validates :email, presence: true, format: { with:VALID_EMAIL_REGEX }#, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { in: 6..20 }, :on => :create
  validates :login, presence: true, length: { in: 6..20 }, uniqueness: { case_sensitive: false }

  belongs_to :department
  has_many :user_menus, :dependent => :destroy
  has_many :menus, through: :user_menus

  has_many :user_categories, :dependent => :destroy
  has_many :categories, through: :user_categories
  # 收到的消息
  has_many :unread_notifications, -> { where "status=0" }, class_name: "Notification", foreign_key: "receiver_id"  

  include AboutStatus
  validates_with MyValidator, on: :update

  # 为了在Model层使用current_user
  def self.current
    Thread.current[:user]
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  # 是否超级管理员,超级管理员不留操作痕迹
  def admin?
    false
    # self.roles.map(&:name).include?("系统管理员")
  end

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  # 获取当前人的菜单
  # def show_menus
  #   return menus_ul(Menu.to_depth(0))
  # end

  def self.status_array
    [
      ["正常",0,"u",100], 
      ["冻结",1,"yellow",100], 
      ["已删除",98,"red",100]
    ]
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='用户名' column='login' class='required rangelength_6_20' display='readonly'/>
        <node name='姓名' column='name' class='required'/>
        <node name='电话' column='tel'/>
        <node name='手机' column='mobile' class='required'/>
        <node name='传真' column='fax'/>
        <node name='职务' column='duty'/>
        <node name='是否单位管理员' column='is_admin' data_type='radio' data='[[0,"否"],[1,"是"]]'/>
        <node name='用户类型' column='user_type' data_type='radio' data='[[0,"单位用户"],[1,"个人用户"]]'/>
        <node name='权限分配' class='tree_checkbox required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Menu"}' partner='menuids'/>
        <node column='menuids' data_type='hidden'/>
        <node name='品目分配' class='tree_checkbox' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Category"}' partner='categoryids'/>
        <node column='categoryids' data_type='hidden'/>
      </root>
    }
  end

  def cando_list(can_opt_arr=[])
    return "" if can_opt_arr.blank?
    arr = [] 
    dialog = "#opt_dialog"
    # 详细
    if can_opt_arr.include?(:read)
      title = self.class.icon_action("详细")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}', '#{dialog}') }]
    end
    # 修改
    if [0,404].include?(self.status) && can_opt_arr.include?(:update)
      arr << [self.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('/kobe/users/#{self.id}/edit','#show_ztree_content #ztree_content')"]
    end
    # 重置密码
    if [0,404].include?(self.status) && can_opt_arr.include?(:reset_password)
      title = self.class.icon_action("重置密码")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}/reset_password', '#{dialog}') }]
    end
    # 冻结
    if [0,404].include?(self.status) && can_opt_arr.include?(:freeze)
      title = self.class.icon_action("冻结")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}/freeze', '#{dialog}') }]
    end
    return arr
  end
  
  # 显示菜单
  def show_menus
    str = ""
    Menu.roots.each do |menu|
      str << menu.show_top(self.menus.uniq)
    end
    str
  end

  # 返回用户的所有操作 用于cancancan {"Department"=> [:create, :read, :update, :update_destroy, :freeze, :update_freeze], "Menu"=>[:create, :read, :update]}
  # 如果是管理员增加一个admin的操作 有admin的可以对别人的订单进行操作
  # menu.can_opt_action = Department|create
  def can_option_hash
    arr = []
    self.menus.each do |m|
      arr << m.can_opt_action if m.can_opt_action.present?
      arr |= m.ancestors.where("can_opt_action is not null and can_opt_action != ''").map(&:can_opt_action)
    end
    rs = {}
    arr.uniq.each do |e| # e = Department|create
      next if e.blank?
      a = e.split("|") 
      if a.length == 2
        rs[a[0]] = [] unless rs.key?(a[0])
        rs[a[0]] << a[1].to_sym
        rs[a[0]] << "update_#{a[1]}".to_sym unless ["create", "read", "update", "update_destroy"].include?(a[1])
      end
    end
    return rs
  end

  # 判断用户是否有某个操作
  def has_option?(option_key='',action='')
    return false if option_key.blank? || action.blank?
    opt = self.can_option_hash[option_key]
    return opt.present? && opt.include?(action.to_sym)
  end

  # 自动获取操作权限
  def set_auto_menu
    self.menu_ids = Menu.where(is_auto: true).map(&:id)
  end

  private

  def create_remember_token
    self.remember_token=User.encrypt(User.new_remember_token)
  end

  # 在layout中展开菜单menu
  # def menus_ul(mymenus = [])
  #   str = "<ul class='nav nav-stacked'>"
  #   mymenus.each{|m| str << menus_li(m) }
  #   str << "</ul>"
  #   return str
  # end

  # def menus_li(menu)
  #   if menu.icon.blank?
  #     case menu.depth
  #     when 0
  #       menu.icon = "icon-caret-right"  
  #     when 1
  #       menu.icon = "icon-chevron-right"
  #     else
  #       menu.icon = "icon-angle-right"
  #     end
  #   end
  #   unless menu.has_children?
  #     str = "<li><a href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span></a></li>"
  #   else
  #     str = "<li><a class='dropdown-collapse' href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span><i class='icon-angle-down angle-down'></i></a>"
  #     str << menus_ul(menu.children)
  #     str << "</li>"
  #   end
  #   return str
  # end

end