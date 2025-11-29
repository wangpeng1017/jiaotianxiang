# ERP系统需求分析报告

**部门**: 运营部  
**模块**: ERP  
**业务范围**: 采购 & 销售

---

## 需求清单与实现状态分析

### 一、天圆需求细则部分

#### 1. 年度计划生成（未实现 ❌）

**需求描述**:
- **本年度销售计划生成**: 系统自动抓取往年销售数据，辅助运营部制定本年度销售计划
- **本年度生产计划生成**: 根据销售计划推算生产计划
- **本年度原辅材料采购计划生成**: 根据生产计划拆分原辅材料需求，自动推算采购计划

**实现状态**: ❌ **未实现**

**解决方案**:
```
模块设计: jtx-erp-plan (新增模块)
├── 年度销售计划
│   ├── 历史数据分析 (基于往年销售记录生成趋势)
│   ├── 计划自动生成 (按产品/客户/月份维度)
│   └── 人工调整与审批
├── 年度生产计划
│   ├── BOM清单关联
│   ├── 产能评估
│   └── 计划拆解 (月度/季度)
└── 年度采购计划
    ├── MRP运算 (Material Requirements Planning)
    ├── 安全库存、在途库存计算
    └── 采购计划汇总与审批

技术实现:
- 数据源: 历史销售订单表、物料清单(BOM)、库存表
- 算法: 时间序列预测 + MRP运算
- 审批流: 集成OA审批流程
```

---

#### 2. 年度采购计划审批与版本管理（部分实现 ⚠️）

**需求描述**:
1. 采购办对各部门采购计划进行审批
2. 采购计划汇总后提报三项工作管理委员会/总经理办公会审批
3. 版本管理: 任何修改自动生成新版本号
4. 审批权限: 重复项目名称、审核顺序的管理提醒
5. 禁取收��: 启用于股、审批流、主栗材料格式
6. 采购月计划、审批,明年全年按月计划时
7. 启动运单批采购计划审批,建立统一维度(物资/工队/服务等分类)
8. 全流程审批权限管理
9. 增辅报表: 流域式查询(类别/方式/金额/时间/供应商等多维度筛选)

**实现状态**: ⚠️ **部分实现**

**已有功能**:
- 基础审批流程
- 采购计划录入

**缺失功能**:
- ❌ 版本管理
- ❌ 分类维度管理(物资/工队/服务)
- ❌ 多层级审批(三项工作/总经理办公会)
- ❌ OA首页"必读"栏目发布
- ❌ 多维度报表查询

**解决方案**:
```sql
-- 1. 增加版本管理表
CREATE TABLE purchase_plan_version (
  id BIGINT PRIMARY KEY,
  plan_id BIGINT,
  version_no VARCHAR(50),
  change_description TEXT,
  create_time DATETIME,
  creator_id BIGINT
);

-- 2. 增加分类维度字段
ALTER TABLE purchase_plan ADD COLUMN category ENUM('物资','工队','服务','其他');
ALTER TABLE purchase_plan ADD COLUMN purchase_method ENUM('公开招标','定向招标','非招标采购');

-- 3. 增加审批流配置表
CREATE TABLE approval_workflow_config (
  id BIGINT PRIMARY KEY,
  workflow_name VARCHAR(100),
  approval_level INT,
  approver_role VARCHAR(50),
  threshold_amount DECIMAL(15,2)
);
```

**功能开发**:
- 版本管理: 每次修改自动生成版本号,保留历史记录
- 集成OA: 调用OA接口推送审批,发布到首页
- 多维度报表: 开发高级筛选组件(供应商/类别/金额/时间区间等)

---

###  二、供应商协同票据升级

#### 3. 供应商门户功能（未实现 ❌）

**需求描述**:
1. **增加供应商上传发票功能**: 发票上传后在ERP系统可查看
   - 开票申请: 供应商在结算完成后对合格订单发起开票申请
   - 发票登记: 上传发票附件,自动带入开票单信息
2. **增加供应商申请付款功能**: 供应商根据发票状态自行申请付款
   - 付款申请: 运营部根据订单状态确认后发起
   - 运营部查看已发票且待付款订单明细
3. **增加供应商对账功能**: 发货、入库、开票、结算等信息对账
   - 采购订单页面增加开票状态、付款状态显示
   - 采购订单详情增加发货、到货、质检、退货信息
   - 采购明细报表增加订货、合格数
   - 优化ERP与仓储、U9的数据传输

**实现状态**: ❌ **未实现**

**解决方案**:
```
供应商门户子系统 (Supplier Portal)
├── 用户认证与权限
│   ├── 供应商账号管理
│   └── 角色权限配置
├── 发票管理
│   ├── 开票申请
│   ├── 发票上传 (PDF/图片)
│   ├── 发票状态跟踪
│   └── OCR识别(可选)
├── 付款管理
│   ├── 付款申请
│   ├── 付款进度查询
│   └── 账期管理
└── 对账管理
    ├── 订单对账单
    ├── 发货/入库明细
    ├── 质检结果查询
    └── 对账差异处理

数据表设计:
- supplier_invoice (供应商发票表)
- supplier_payment_request (付款申请表)
- supplier_reconciliation (对账单表)

接口开发:
- 供应商登录API
- 发票上传/查询API
- 付款申请API
- 对账单查询API

前端开发:
- 供应商门户页面 (独立子系统或H5页面)
- 运营部审核页面
```

---

### 三、销售订单管理优化

#### 4. 销售订单自动关闭功能（未实现 ❌）

**需求描述**:
1. 增加销售订单自动关闭功能,未完成订单可关闭
   - 增加关闭状态,关闭后不再产生发货通知单和出库信息
   - 已关闭订单不允许发起新出库通知单
   - 下销售订单时显示产品当前库存

**实现状态**: ❌ **未实现**

**解决方案**:
```sql
-- 增加订单状态字段
ALTER TABLE sale_order ADD COLUMN order_status ENUM(
  '草稿','待审核','已审核','执行中','已完成','已关闭','已取消'
) DEFAULT '草稿';

ALTER TABLE sale_order ADD COLUMN close_reason VARCHAR(500);
ALTER TABLE sale_order ADD COLUMN close_time DATETIME;
ALTER TABLE sale_order ADD COLUMN close_user_id BIGINT;

-- 增加关闭日志表
CREATE TABLE sale_order_close_log (
  id BIGINT PRIMARY KEY,
  order_id BIGINT,
  close_reason TEXT,
  close_time DATETIME,
  operator_id BIGINT
);
```

**业务逻辑**:
```java
// 订单关闭校验
public void closeSaleOrder(Long orderId, String reason) {
  // 1. 校验订单状态(不能是已完成/已关闭)
  // 2. 禁用"生成发货通知单"按钮
  // 3. 标记订单为已关闭状态
  // 4. 记录关闭原因和操作人
  // 5. 触发库存释放(如有预占)
}

// 下单时显示库存
public SaleOrderVO createOrder(SaleOrderDTO dto) {
  // 查询产品实时库存
  List<Stock> stocks = stockService.getStockByProductIds(productIds);
  // 在订单明细中展示库存数量
  orderItems.forEach(item -> {
    item.setCurrentStock(stocks.get(item.getProductId()));
  });
}
```

---

#### 5. 财务状态跟踪（部分实现 ⚠️）

**需求描述**:
1. 增加供应商付款情况跟踪: 采购订单页面增加开票状态、付款状态
2. 增加客户收款情况跟踪: 销售订单页面增加开票状态、收款状态

**实现状态**: ⚠️ **部分实现**

**已有功能**:
- 基础订单管理

**缺失功能**:
- ❌ 开票状态显示(是否开票/是否入账)
- ❌ 付款/收款状态显示
- ❌ 与财务系统联动

**解决方案**:
```sql
-- 采购订单增加财务字段
ALTER TABLE purchase_order ADD COLUMN invoice_status ENUM('未开票','已开票','已入账');
ALTER TABLE purchase_order ADD COLUMN payment_status ENUM('未付款','部分付款','已付款');
ALTER TABLE purchase_order ADD COLUMN invoice_amount DECIMAL(15,2);
ALTER TABLE purchase_order ADD COLUMN paid_amount DECIMAL(15,2);

-- 销售订单增加财务字段
ALTER TABLE sale_order ADD COLUMN invoice_status ENUM('未开票','已开票','已入账');
ALTER TABLE sale_order ADD COLUMN receipt_status ENUM('未收款','部分收款','已收款');
ALTER TABLE sale_order ADD COLUMN invoice_amount DECIMAL(15,2);
ALTER TABLE sale_order ADD COLUMN received_amount DECIMAL(15,2);
```

**集成方案**:
- 与财务模块(jtx-erp-finance)集成
- 开票后自动更新订单发票状态
- 付款/收款后自动更新订单财务状态
- 提供API供财务人员手动更新状态

---

#### 6. 物料编辑权限分离（未实现 ❌）

**需求描述**:
1. 物料数据拆分: 基本信息 & 业务信息独立修改
2. 原"编辑"权限: 只允许特定人员修改,对其他人隐藏
3. 新增"业务编辑"权限: 允许业务人员修改"是否批次管理""是否颜码""来料检测"等字段,不触发审批流程

**实现状态**: ❌ **未实现**

**解决方案**:
```sql
-- 物料表拆分
-- 基本信息表 (material_basic_info)
CREATE TABLE material_basic_info (
  id BIGINT PRIMARY KEY,
  material_code VARCHAR(50),
  material_name VARCHAR(200),
  category_id BIGINT,
  unit VARCHAR(20),
  -- ...其他基本信息
  update_time DATETIME,
  updater_id BIGINT
);

-- 业务信息表 (material_business_info)
CREATE TABLE material_business_info (
  id BIGINT PRIMARY KEY,
  material_id BIGINT,
  is_batch_management TINYINT(1),
  is_barcode TINYINT(1),
  need_incoming_inspection TINYINT(1),
  -- ...其他业务属性
  update_time DATETIME,
  updater_id BIGINT
);

-- 权限配置
INSERT INTO sys_permission VALUES 
('material:basic:edit', '物料基本信息编辑'),
('material:business:edit', '物料业务信息编辑');
```

**前端实现**:
```javascript
// 根据权限显示/隐藏按钮
computed: {
  canEditBasic() {
    return this.$auth.hasPermission('material:basic:edit');
  },
  canEditBusiness() {
    return this.$auth.hasPermission('material:business:edit');
  }
}

// 业务信息修改不触发审批流
async saveBusinessInfo() {
  // 直接保存,不调用审批流程
  await this.$api.updateMaterialBusinessInfo(this.form);
}
```

---

#### 7. 采购/销售出入库数据对接优化（部分实现 ⚠️）

**需求描述**:
1. 销售订单增加: 申请开票、实际开票、实际收款信息
2. 销售出库明细增加: 含税核定价、出库总额信息
3. 销售开票流程: 运营部根据出库信息发起开票申请 -> OA审批 -> 财务开票并上传发票到ERP
4. 运营部可查看财务上传的发票

**实现状态**: ⚠️ **部分实现**

**已有功能**:
- 基础出入库管理

**缺失功能**:
- ❌ 开票申请流程
- ❌ OA审批集成
- ❌ 发票上传与查看
- ❌ 含税价格字段

**解决方案**:
```sql
-- 销售订单增加开票字段
ALTER TABLE sale_order ADD COLUMN apply_invoice_amount DECIMAL(15,2) COMMENT '申请开票金额';
ALTER TABLE sale_order ADD COLUMN actual_invoice_amount DECIMAL(15,2) COMMENT '实际开票金额';
ALTER TABLE sale_order ADD COLUMN actual_receipt_amount DECIMAL(15,2) COMMENT '实际收款金额';

-- 销售出库单增加字段
ALTER TABLE sale_outbound ADD COLUMN tax_included_price DECIMAL(15,2) COMMENT '含税核定价';
ALTER TABLE sale_outbound ADD COLUMN total_amount_with_tax DECIMAL(15,2) COMMENT '含税总额';

-- 开票申请表
CREATE TABLE invoice_apply (
  id BIGINT PRIMARY KEY,
  order_id BIGINT,
  apply_amount DECIMAL(15,2),
  apply_reason TEXT,
  apply_time DATETIME,
  applicant_id BIGINT,
  oa_process_id VARCHAR(100),
  approval_status ENUM('待审批','已审批','已驳回'),
  invoice_file_url VARCHAR(500),
  invoice_upload_time DATETIME
);
```

**流程开发**:
```java
// 1. 运营部发起开票申请
public void applyInvoice(InvoiceApplyDTO dto) {
  // 创建开票申请记录
  InvoiceApply apply = new InvoiceApply();
  apply.setOrderId(dto.getOrderId());
  apply.setApplyAmount(dto.getAmount());
  
  // 调用OA接口发起审批流程
  String processId = oaService.startInvoiceApprovalProcess(apply);
  apply.setOaProcessId(processId);
  
  invoiceApplyMapper.insert(apply);
}

// 2. OA审批回调
public void onOAApprovalCallback(String processId, String result) {
  InvoiceApply apply = invoiceApplyMapper.getByProcessId(processId);
  if ("approved".equals(result)) {
    apply.setApprovalStatus("已审批");
    // 通知财务人员开票
    notifyFinanceToDepartment(apply);
  }
}

// 3. 财务上传发票
public void uploadInvoice(Long applyId, MultipartFile file) {
  String fileUrl = fileService.upload(file);
  invoiceApplyMapper.updateInvoiceFile(applyId, fileUrl);
}
```

---

### 四、采购模块功能优化

#### 8. 采购订单批量导入（未实现 ❌）

**需求描述**:
- 采购订单增加批量导入功能

**实现状态**: ❌ **未实现**

**解决方案**:
```java
// Excel导入模板定义
@Data
public class PurchaseOrderImportVO {
    @ExcelProperty("供应商编码")
    private String supplierCode;
    
    @ExcelProperty("物料编码")
    private String materialCode;
    
    @ExcelProperty("数量")
    private BigDecimal quantity;
    
    @ExcelProperty("单价")
    private BigDecimal price;
    
    @ExcelProperty("交货日期")
    private Date deliveryDate;
}

// 批量导入服务
@Service
public class PurchaseOrderImportService {
    
    public ImportResult batchImport(MultipartFile file) {
        List<PurchaseOrderImportVO> dataList = ExcelUtil.read(file, PurchaseOrderImportVO.class);
        
        // 数据校验
        List<String> errors = validate(dataList);
        if (!errors.isEmpty()) {
            return ImportResult.fail(errors);
        }
        
        // 批量插入
        List<PurchaseOrder> orders = convert(dataList);
        purchaseOrderMapper.batchInsert(orders);
        
        return ImportResult.success(orders.size());
    }
}
```

---

#### 9. "开票时限"限制功能调整（需确认 ⚠️）

**需求描述**:
- "开票时限"限制功能不合适

**实现状态**: ⚠️ **需确认**

**解决方案**:
1. 与业务部门确认具体不合适的原因
2. 可选方案:
   - 移除开票时限限制
   - 调整时限计算规则(从验收日期/入库日期/对账日期起算)
   - 改为预警提醒而非强制限制

---

#### 10. 采购结算单打印模板增加"程号"（简单实现 ✅）

**需求描述**:
- 采购结算单打印模板增加"程号"字段

**实现状态**: ✅ **易实现**

**解决方案**:
```xml
<!-- 修改打印模板 -->
<template>
  <div class="settlement-print">
    <div class="header">
      <span>结算单号: {{settlementNo}}</span>
      <span>程号: {{programNo}}</span> <!-- 新增 -->
    </div>
    ...
  </div>
</template>
```

```sql
-- 如果数据库缺少字段
ALTER TABLE purchase_settlement ADD COLUMN program_no VARCHAR(50) COMMENT '程号';
```

---

#### 11. 发票登记增加"采购入库单打印模板"（简单实现 ✅）

**需求描述**:
- 发票登记版块—打印—增加采购入库单打印模块

**实现状态**: ✅ **易实现**

**解决方案**:
```javascript
// 在发票登记页面增加打印入库单按钮
methods: {
  printInboundOrder(invoiceId) {
    // 1. 查询发票关联的入库单
    const inboundOrders = await this.$api.getInboundByInvoice(invoiceId);
    
    // 2. 调用打印组件
    this.$print({
      template: 'inbound-order-template',
      data: inboundOrders
    });
  }
}
```

---

#### 12. 增加"发票收迎开立"功能（需求不明确 ⚠️）

**需求描述**:
- 增加 发票收迎开立

**实现状态**: ⚠️ **需求不明确**

**建议**:
请确认"发票收迎开立"的具体含义:
- 是否指"发票收款确认"?
- 是否指"发票开立流程"?
- 是否指特定的财务术语?

---

#### 13. 采购明细汇总优化（未实现 ❌）

**需求描述**:
1. 不合计已关闭订单且无入库数量/合格数量的数据
2. 增加筛选内容:
   - 下订单具体时间
   - 入库单号
   - 入库时间
   - 支持按供应商名称、料品名称/编码、入库时间区间筛选
3. 页面底部显示采购数量及金额汇总

**实现状态**: ❌ **未实现**

**解决方案**:
```sql
-- 采购明细汇总视图
CREATE VIEW v_purchase_detail_summary AS
SELECT 
  po.order_no,
  po.order_date,
  po.supplier_id,
  s.supplier_name,
  poi.material_id,
  m.material_code,
  m.material_name,
  poi.quantity AS order_quantity,
  poi.price,
  poi.amount AS order_amount,
  ib.inbound_no,
  ib.inbound_date,
  ibi.quantity AS inbound_quantity,
  ibi.qualified_quantity,
  po.order_status
FROM purchase_order po
LEFT JOIN purchase_order_item poi ON po.id = poi.order_id
LEFT JOIN supplier s ON po.supplier_id = s.id
LEFT JOIN material m ON poi.material_id = m.id
LEFT JOIN inbound_order_item ibi ON poi.id = ibi.purchase_item_id
LEFT JOIN inbound_order ib ON ibi.inbound_id = ib.id
WHERE po.order_status != '已关闭' 
  OR (ibi.quantity > 0 OR ibi.qualified_quantity > 0);
```

```javascript
// 前端高级筛选组件
<el-form :model="queryForm">
  <el-row>
    <el-col :span="6">
      <el-form-item label="供应商">
        <el-select v-model="queryForm.supplierId" filterable>
          <el-option v-for="s in suppliers" :key="s.id" :value="s.id" :label="s.name"/>
        </el-select>
      </el-form-item>
    </el-col>
    <el-col :span="6">
      <el-form-item label="物料">
        <el-input v-model="queryForm.materialKeyword" placeholder="名称/编码"/>
      </el-form-item>
    </el-col>
    <el-col :span="12">
      <el-form-item label="入库时间">
        <el-date-picker 
          v-model="queryForm.inboundDateRange" 
          type="daterange"
          range-separator="至"
        />
      </el-form-item>
    </el-col>
  </el-row>
</el-form>

<!-- 底部汇总 -->
<div class="summary-footer">
  <span>合计数量: {{summary.totalQuantity}}</span>
  <span>合计金额: {{summary.totalAmount}}</span>
</div>
```

---

## 总结

### 实现状态统计

| 状态 | 数量 | 占比 | 需求编号 |
|------|------|------|---------|
| ❌ 未实现 | 8 | 62% | 1, 3, 4, 6, 8, 9, 12, 13 |
| ⚠️ 部分实现 | 3 | 23% | 2, 5, 7 |
| ✅ 易实现 | 2 | 15% | 10, 11 |

### 优先级建议

#### P0 (高优先级 - 核心业务流程)
1. **供应商门户 (#3)** - 影响供应商协同效率
2. **财务状态跟踪 (#5, #7)** - 运营部急需的可视化功能
3. **销售订单关闭 (#4)** - 业务流程闭环
4. **采购明细汇总 (#13)** - 运营部日常使用

#### P1 (中优先级 - 管理提升)
5. **年度计划生成 (#1)** - 需要较大开发量,建议分期实现
6. **年度计划审批优化 (#2)** - 补充版本管理和分类维度
7. **物料权限分离 (#6)** - 提升数据管理灵活性

#### P2 (低优先级 - 便利性功能)
8. **采购批量导入 (#8)** - 提升录入效率
9. **打印模板优化 (#10, #11)** - 简单实现

#### 待确认
10. **开票时限调整 (#9)** - 需业务部门明确需求
11. **发票收迎开立 (#12)** - 需求不明确

### 开发资源评估

**预估工作量** (人/天):
- P0 需求: 约45-60人/天
- P1 需求: 约30-40人/天
- P2 需求: 约5-8人/天

**建议分3期实施**:
- **第一期 (2-3个月)**: P0 需求
- **第二期 (1-2个月)**: P1 需求
- **第三期 (0.5-1个月)**: P2 需求
