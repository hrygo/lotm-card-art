# 姓名艺术字：创作输入与合成合同

这是一份侧车brief约定，不增加现有task.schema未支持的kind或字段；不是foolkit已实现的命令接口。

## 创作输入

- identity_source：权威主体任务/卡片身份路径、哈希、字段名；exact_text逐字取自主角姓名，不让Agent另造简称。
- language、reading_order：中文与从左到右等明确顺序。
- pathway_id、design_tokens：与该途径的材质/配色/雕刻语法一致，姓名可读性优先。
- references：实际可访问的母框、圣徽或认可字形风格，标明用途；每张实际作为附件发送。
- master_geometry_id、master_geometry_sha256、target_inner_rect、max_visible_width/height：引用已冻结母框的唯一姓名内区及其版本，所有品质共享，保留安全留距；不得根据漂移变体重新测区补偿。
- constraints：完整准确姓名、独立艺术字、无附加字/边框/徽记、不用过度花饰遮挡笔画。

## 输出与装配

保留生成原图、task、call、receipt和逐字审核。背景不透明时先标记needs-background-extraction，不能直接当透明文字层。
通过净底与逐字审核后记录clean_asset、sha256、visible_ink_bbox、effect_bbox（阴影/辉光）、exact_text及审核依据。字形本体居中，效果边界只参与溢出检查，避免偏向单侧的辉光推歪姓名。
程序对可见字形边界等比contain进姓名内区：scale=min(允许宽/字形宽,允许高/字形高)；offset=内区中心-scale×字形边界中心。绘制整个源图时必须保留该偏移，不再次按PNG画布中心对齐。
生成后测量最终像素的左右/上下中心误差；不能仅用配置坐标证明已经精确居中。精确姓名仍保留为元数据供校验；元数据不能代替卡面文字正确。

当前框架套件不含角色姓名艺术字。姓名资产的制作、逐字审核与用户批准独立记录，不由框架完成状态推导。

五档层级主色不自动作用于姓名艺术字；姓名保持途径协调与可读性。当前Klein实例由Agentic字形净底后转单色烟紫墨，实际双轴居中；这是可复用的定位方法，不是所有姓名必须单色的限制。
