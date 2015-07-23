# -*- encoding : utf-8 -*-
module AboutAncestry

	def self.included(base)
    base.extend(AncestryClassMethods)
    base.class_eval do 
      # 自己和后代
      # scope :self_and_descendants, lambda { |id| where(["FIND_IN_SET(?, CONCAT_WS(',',id,REPLACE(ancestry,'/',','))) >0", id ]) }
      default_scope -> {order(:ancestry, :sort, :id)}
      # 树形结构
      has_ancestry :cache_depth => true
    end
  end

  # 拓展类方法
  module AncestryClassMethods
	  def get_json(node) # name -> node
	    # if name.blank?
	    #   nodes = self.attribute_method?("status") ? self.where.not(status: 404) : self.all
	    # else
     #    cdt = self.attribute_method?("status") ? "and status != 404" : ""
	    #   sql = "SELECT DISTINCT a.id,a.name,a.ancestry FROM #{self.to_s.tableize} a INNER JOIN  #{self.to_s.tableize} b ON (FIND_IN_SET(a.id,REPLACE(b.ancestry,'/',',')) > 0 OR a.id=b.id OR (LOCATE(CONCAT(b.ancestry,'/',b.id),a.ancestry)>0)) WHERE b.name LIKE ? #{cdt} ORDER BY a.ancestry"
	    #   nodes = self.find_by_sql([sql,"%#{name}%"])
	    # end
      # 如果node为空 生成树的json 取所有状态不是已删除的节点 例如 menu、role等
      # 如果node不为空 取node和他的子孙们 例如 department 
      if node.blank?
        nodes = self.attribute_method?("status") ? self.where.not(status: 404) : self.all
      else
        # nodes = node.has_children? ? node.descendants.where.not(status: 404) : []
        # nodes << node
        nodes = node.subtree.where.not(status: 404)
      end
	    json = nodes.map{|n|%Q|{"id":#{n.id}, "pId":#{n.pid}, "name":"#{n.name}"}|}
	    return "[#{json.join(", ")}]" 
	  end

	  # zTree移动节点
	  def ztree_move_node(source_id,target_id,move_type,is_copy=false)
	    return if source_id.blank? || target_id.blank? || move_type.blank?
	    source_node = self.find_by(id: source_id)
	    target_node = self.find_by(id: target_id)
	    return unless source_node && target_node
	    if move_type == "inner" 
	      source_node.reset_parent(target_node)
	    else
	      if source_node.parent != target_node.parent
	        if target_node.root?
	          source_node.parent = nil
	          source_node.siblings_move(target_node,move_type)
	        else
	          source_node.reset_parent(target_node.parent)
	        end
	      end
	      source_node.siblings_move(target_node,move_type)
	    end
	    return "targetId=#{target_id},sourceId=#{source_id},moveType=#{move_type},isCopy=#{is_copy}"
	  end
  end

	# 获取父节点名称
	def parent_name
  	self.parent.nil? ? '' : self.parent.name
  end

  # 获取父节点ID ,这里是zTree的PID，与parent_id不同 ，根节点的parent_id是nil，而pid为0
  def pid
    # self.parent_id.nil? ? 0 : self.parent_id
    self.ancestry.nil? ? 0 : self.ancestry.split('/').last
  end

  # 同级目录内移动
  def siblings_move(target_node,move_type)
      siblings = target_node.siblings
      tmp = i = 0
      siblings.each do |s|
        i = i + 1
        if s == target_node
          if move_type == "prev"
            tmp = i
            s.sort = i + 1
          elsif move_type == "next"
            s.sort = i
            tmp = i + 1
          end
          i = i + 1  
        elsif s == self 
            i = i - 1  # 跳过源节点
            next
        else
          s.sort = i
        end
        s.save
      end
      self.sort = tmp
      self.save
  end
  
  # 重新指定父节点
  def reset_parent(target_node)
    self.parent = target_node
    self.sort = target_node.children.count + 1
    self.save
  end

end