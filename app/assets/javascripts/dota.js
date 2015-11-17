$(function(){

  // 购物车页面商品增减
  $(document).on('click', '.decrease_num', function(event) {
    $num = $('#item-num-' + $(this).parent().attr('item_id'));
    num = $num.val();
    if ($.isBlank(parseInt(num))){
      $num.val(1);
    }
    if (parseInt(num) > 1){
      $num.val(parseInt(num) - 1);
      // 计算单个商品总价
      calc_item($(this).parent().attr('item_id'), $num.val());
      // 计算购物车总价
      calc_total();
      $.get("/cart/change/" + $(this).parent().attr('pid') + "?agent_id=" + $(this).parent().attr("aid") + "&set=1&a=1&num=" + $num.val());
    };
  });

  $(document).on('click', '.increase_num', function(event) {
    $num = $('#item-num-' + $(this).parent().attr('item_id'));
    num = $num.val();
    if ($.isBlank(parseInt(num))){
      $num.val(1);
    }
    if ((parseInt(num) + 1) > 9999){
      $num.val(9999);
    }else{
      $num.val(parseInt(num) + 1);
    }
    // 计算单个商品总价
    calc_item($(this).parent().attr('item_id'), $num.val());
    // 计算购物车总价
    calc_total();
    $.get("/cart/change/" + $(this).parent().attr('pid') + "?agent_id=" + $(this).parent().attr("aid") + "&set=1&a=1&num=" + $num.val());
  });


  // 提交
  $("#order_create_form").submit(function(){
    if(!$("#save_address_btn").is(":hidden")){
      $("#save_address_btn").focus();
      art_alert("请先保存收货地址");
      return false;
    }

    if(!$("#save_yw_type_btn").is(":hidden")){
      $("#save_yw_type_btn").focus();
      art_alert("请先保存采购方式");
      return false;
    }

    var yw_type = $("input:radio[name='order\[yw_type\]']:checked").val();
    if ($.isBlank(yw_type)){
      art_alert("请选择采购方式");
      return false;
    }

    if(yw_type == "xygh"){
      if (isEmpty($("#order_payer").val())){
        art_alert("请填写发票抬头");
        return false;
      }
    }

    if (yw_type == "xygh" && $.isBlank($("input:radio[name='order\[budget_id\]']:checked").val())){
      art_alert("单位采购请选择预算审批单");
      return false;
    }

    var price_flag = false;
    $(".save_price_span").each(function(){ 
      if(!$(this).is(":hidden")){
        price_flag = true;
        return false;
      } 
    });

    if(price_flag){
      $(".save_price_span").focus();
      art_alert("请先保存采购人价格");
      return false;
    }
    
  }).on("ajax:beforeSend", function(){
    $("#order_submit_btn").hide();
    $("#loading_btn").show();
  }).on("ajax:success", function(e, r, status, xhr){
    if (r.success){
      window.location.href = "/order_success.html";
    }else{
      $("#order_msg").text(r.msg);
      $("#order_msg").show();
      $("#order_submit_btn").show();
      $("#loading_btn").hide();
    }
  }).on("ajax:error", function(e, xhr, status, error){
    alert("系统繁忙，请刷新页面稍后再试！");
    $("#order_submit_btn").show();
    $("#loading_btn").hide();
  }).on("ajax:complete", function(e, xhr, status, error){
    // $("#order-loading").remove();
  });
  // 提交END


  // 下单采购人价格keyup paste
  // $(document).on('keyup paste', '.item_real_price', function(){
    
  // }).css("ime-mode", "disabled"); //CSS设置输入法不可用  

// 勾选商品
  $(".cart_checkbox").change(function(){
    var item_id = $(this).attr("item_id");
    var pid = $(this).attr("pid");
    var aid = $(this).attr("aid");
    if ($(this).prop("checked") == false){
      if ($("[name='p-" + aid + "']:checkbox:checked").length == 0){
        $("#all-" + $(this).attr("aid")).prop("checked", false);
      }
      $(this).closest(".merchandise").addClass("bg7");
      $("#item-total-" + item_id).removeClass("cart-item-total");
    }else{
      $("#all-" + $(this).attr("aid")).prop("checked", true);
      $(this).closest(".merchandise").removeClass("bg7");
      $("#item-total-" + item_id).addClass("cart-item-total");
    }
    // 计算购物车总价
    calc_total();
    $.get("/cart/dynamic?pids=" + pid + "&agent_id=" + aid + "&ready=" + $(this).prop("checked"));
  });

  // 勾选供应商
  $(".cart_agent_checkbox").change(function(){
    var item_id = $(this).attr("item_id");
    var aid = $(this).attr("aid");
    var pids = new Array();
    if ($(this).prop("checked") == false){
      $(this).closest(".merchandisetitle").addClass("bg7");
      $("[name='p-" + aid + "']:checkbox").each(function(){
        pids.push($(this).attr("pid"));
        $(this).prop("checked", false);
        $(this).closest(".merchandise").addClass("bg7");
        $("#item-total-" + item_id).removeClass("cart-item-total");
      })
    }else{
      $(this).closest(".merchandisetitle").removeClass("bg7");
      $("[name='p-" + aid + "']:checkbox").each(function(){
        pids.push($(this).attr("pid"));
        $(this).prop("checked", true);
        $(this).closest(".merchandise").removeClass("bg7");
        $("#item-total-" + item_id).addClass("cart-item-total");
      })
    }
    // 计算购物车总价
    calc_total();
    $.get("/cart/dynamic?pids=" + pids.join("_") + "&agent_id=" + aid + "&ready=" + $(this).prop("checked"));
  });
  // 勾选供应商END

  // 购物车数量
  $(document).on('blur', '.cart-num-field', function(){
    var num = parseInt($(this).val());
    if (isEmpty(num)){
      num = 1;
    }else{
      if (num <= 1){
        num = 1;
      }
      if (num >= 9999){
        num = 9999;
      }
    }
    $(this).val(num);
    // 计算单个商品总价
    calc_item($(this).parent().attr('item_id'), num);
    // 计算购物车总价
    calc_total();
    $.get("/cart/change/" + $(this).parent().attr('pid') + "?agent_id=" + $(this).parent().attr("aid") + "&set=1&a=1&num=" + num);
  });

  // 选择采购方式
  $("input:radio[name='order\[yw_type\]']").change(function(){
    var title = "";
    if ($(this).val() == "xygh"){
      $("#order_sfz_div").hide();
      // $("#plans_div").show();
      $("#payer_grcg").hide();
      $("#order_payer").show();
      title = $("#order_payer").val();
    }else{
      $("#order_sfz_div").show();
      // $("#plans_div").show();
      $("#payer_grcg").show();
      $("#order_payer").hide();
      title = "个人";
    }
    $("#current_yw_type_info").text($(this).next().text() + "（发票抬头：" + title + "）");
  });
})


// 检查采购方式
function checkYw_type(){
  var errorFlag = false;
  var errorMessage = null;
  var value = null;
  $("#order_yw_type_div_error").html("");
  $("#order_yw_type_div").removeClass("errorinformation");
  $("#order_payer_div_error").html("");
  $("#order_payer_div").removeClass("errorinformation");
  $("#order_sfz_div_error").html("");
  $("#order_sfz_div").removeClass("errorinformation");
  value = $("input:radio[name='order\[yw_type\]']:checked").val();
  if (isEmpty(value)) {
    errorFlag = true;
    errorMessage = "请选择采购方式";
    $("#order_yw_type_div_error").html(errorMessage);
    $("#order_yw_type_div").addClass("errorinformation");
  }else{
    $("#order_yw_type_div_error").html("");
    $("#order_yw_type_div").removeClass("errorinformation");
  }

  if (value == "xygh"){
    budget_value = $("input:radio[name='order\[budget_id\]']:checked").val();
    if (isEmpty(budget_value)) {
      errorFlag = true;
      errorMessage = "单位采购请选择预算申请单";
      $("#order_yw_type_div_error").html(errorMessage);
      $("#order_yw_type_div").addClass("errorinformation");
    }else{
      $("#order_yw_type_div_error").html("");
      $("#order_yw_type_div").removeClass("errorinformation");
    }
  }

  if(value == "xygh"){
    value = $("#order_payer").val();
    if (isEmpty(value)) {
      errorFlag = true;
      errorMessage = "请填写发票抬头";
      $("#order_payer_div_error").html(errorMessage);
      $("#order_payer_div").addClass("errorinformation");
    }else{
      $("#order_payer_div_error").html("");
      $("#order_payer_div").removeClass("errorinformation");
    }
  }

  if(value == "grcg"){
    value = $("#order_sfz").val();
    if (isEmpty(value) || value.length != 18) {
      errorFlag = true;
      errorMessage = "请填写正确的身份证号码";
      $("#order_sfz_div_error").html(errorMessage);
      $("#order_sfz_div").addClass("errorinformation");
    }else{
      $("#order_sfz_div_error").html("");
      $("#order_sfz_div").removeClass("errorinformation");
    }
  }
  if (errorFlag) {
    return false;
  }
  return true;
}

// 检查收货地址
function checkAddress(divId){
  var errorFlag = false;
  var errorMessage = null;
  var value = null;
  if (divId == "order_buyer_man_div") {
    value = $("#order_buyer_man").val();
    if (isEmpty(value)) {
      errorFlag = true;
      errorMessage = "请您填写收货人姓名";
    }
  }else if (divId == "order_buyer_addr_div") {
    value = $("#order_buyer_addr").val();
    if (isEmpty(value)) {
      errorFlag = true;
      errorMessage = "请您填写收货详细地址";
    }
  }else if (divId == "order_buyer_tel_div") {
    value = $("#order_buyer_tel").val();
    if (isEmpty(value)) {
      errorFlag = true;
      errorMessage = "请您填写座机";
    }
  }else if (divId == "order_buyer_mobile_div") {
    value = $("#order_buyer_mobile").val();
    if (isEmpty(value)) {
      errorFlag = true;
      errorMessage = "请您填写手机号";
    }else if(value.length != 11){
      errorFlag = true;
      errorMessage = "请您填写11位手机号";
    }
  }

  if (errorFlag) {
    $("#" + divId + "_error").html(errorMessage);
    $("#" + divId).addClass("errorinformation");
    return false;
  } else {
    $("#" + divId).removeClass("errorinformation");
    $("#" + divId + "_error").html("");
  }
  return true;
}

// 保存采购方式
function save_yw_type(){
  var checkr = true;
  // 验证收货人信息是否正确
  if (!checkYw_type()) {
    checkr = false;
  }
  if (!checkr) {
    return;
  }
  
  $("#step_yw_type").show();
  $("#step_yw_type_current").hide();
}


// 修改采购方式
function choose_yw_type(){
  $("#step_yw_type").hide();
  $("#step_yw_type_current").show();
}

// 保存收货地址
function save_address(){
    var checkr = true;
  // 验证收货人信息是否正确
  if (!checkAddress("order_buyer_man_div")) {
    checkr = false;
  }
  if (!checkAddress("order_buyer_addr_div")) {
    checkr = false;
  }
  if (!checkAddress("order_buyer_tel_div")) {
    checkr = false;
  }
  
  $("#step_address_current .newinfo").each(function(){
    if (!checkAddress($(this).attr("id"))) {
      checkr = false;
      return false;
    }
  });
  if (!checkr) {
    return;
  }
  
  $("#current_address_info").text($("#order_buyer_man").val() + " " + $("#order_buyer_addr").val() + " " + $("#order_buyer_tel").val() + " " + $("#order_buyer_mobile").val() + " 要求交付日期：" + $("#order_deliver_at").val());
  $("#step_address").show();
  $("#step_address_current").hide();
}

// 修改收货地址
function choose_address(){
  $("#step_address").hide();
  $("#step_address_current").show();
}

// 计算购物车总价
function calc_total(){
  sum_total = $('#item-buy-sum_total');
  current_total = 0.0;
  $(".cart-item-total").each(function(){current_total += parseFloat($(this).text());})
  sum_total.text(current_total.toFixed(2)).change();
}

// 商品小计
function calc_item(item_id, num){
  price_input = $('#item-price-' + item_id);
  total = $('#item-total-' + item_id);
  total.text((parseInt(num)*parseFloat(price_input.text())).toFixed(2));
}

// 修改报价
function change_real_price(item_id){
  $("#show-price-" + item_id).hide();
  $("#edit-price-" + item_id).show();
}

// 确认报价
function save_real_price(item_id){
  // 检查价格
  var $t = $("#item_price_" + item_id);
  $t.val($t.val().replace(/[^0-9.]/g,'')); 
  var max_price = $t.attr("max_price");
  if (isEmpty($t.val()) || parseInt($t.val()) < 0 || parseFloat($t.val()) > parseFloat(max_price)){
    $t.val(max_price);
  }
  // 计算总价
  var num = $t.attr('num');
  $("#cart-item-total-" + item_id).text((parseInt(num) * parseFloat($t.val())).toFixed(2));
  var current_total = 0.0;
  $(".cart-item-total").each(function(){current_total += parseFloat($(this).text());})
  $("#order_total").text(current_total.toFixed(2)).change();

  $("#item-price-show-" + item_id).text(parseFloat($t.val()).toFixed(2));

  $("#show-price-" + item_id).show();
  $("#edit-price-" + item_id).hide();
}
