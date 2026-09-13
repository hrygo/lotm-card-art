# 公共物料库 v1

资产单一清单为 catalog.json。status=pending/proposed 表示实际已有、待视觉验收，不表示正式批准；gaps 明列未制作范围。
当前为深色公共底座＋愚者纵向试点。5项候选栅格包含1项复用旧纸纹与4项新增选用素材；12个新组件；10个复用愚者数字原型。另存1项不合格冷银首稿。不同登记版本不重复计数，人物插画不算公共物料。

## 五层映射

| 层 | 实物 |
| --- | --- |
| 公共基础 | paper / silver / gold |
| 公共组件 | outer-band、name-bed、header-bed、side-wear |
| 公共层级 | window-low / mid / high / true-god |
| 途径基础 | fool-veil、10个现有愚者复合印记 |
| 途径分层 | fool-low / mid / high / true-god；high-filament为可选装饰 |

复用不是每层重新生一整张图。栅格提供物性，JSON矢量/遮罩提供结构，recipe提供装配关系。素材原始像素1024×1536；输出放大不代表原生细节。

## 组件接口

组件JSON：id/version/status/scope/shapes。shapes复用v1 rect/ellipse/path/text合同。
mask组件不能含text；路径使用偶奇填充，同一路径的第二条闭合轮廓形成孔洞。mask只取alpha，颜色亮度不改变遮罩强度；stroke可做细带遮罩。矩形和椭圆不能通过嵌套数组隐式挖孔，应使用同一path的子路径。
所有坐标为1000×1500、y向下。anchors是命名rect表，node.rect、shape.rect、identity.layout.rect可引用；path.commands仍是绝对设计坐标，不随rect自动缩放。

## 配方接口

recipe必需version=2.0.0、mode=material-study、id、profile、background、anchors、nodes。
profile读取config/project.json；background允许#RRGGBB或none（真实透明画布）。
nodes是有序、唯一id的平面分组，每组来源恰选receipt / vector / shapes之一。
receipt必须指向已登记素材；vector与mask引用为path+sha256；所有路径均在仓库内。

| 参数 | 范围与含义 |
| --- | --- |
| rect / fit | 栅格位置；cover或contain，默认cover |
| opacity | 0–1，默认1 |
| blend | normal / multiply / screen / soft-light |
| mask | 组件引用；先合成组，再裁切 |
| feather | 0–40设计单位，需显式mask；高斯边缘允许向外延伸 |
| brightness | -0.5–0.5，默认0；这是亮度调整，不是物理曝光EV |
| saturation | 0–2，默认1 |
| shadow | x/y：-30–30；blur：0–40；opacity：0–1；黑色接触投影 |

每组先绘制来源，再调整明暗/饱和度，再遮罩羽化，最后按混合/透明度/阴影叠加。随后是试装标签和核心姓名，后者不受前面材质滤镜影响。
identity.layout只保存版式；subject_receipt读取主体姓名，或用明确的test_name作版式实验；两者互斥。字号至少32，不截断、不自动缩字。四档对照使用测试姓名，同一人物插画不代表相应序列事实。

## 执行与门禁

```bash
python3 tools/materialctl.py render production/library/recipes/fool-low-named.json --out artifacts/production/my-new-material-run
python3 tools/materialctl.py gate artifacts/production/my-new-material-run
python3 tools/materialctl.py gate artifacts/production/my-new-material-run --release
```

第三条必定失败：material-study不是正式卡牌发布入口。正式v1仍走tools/production.py；新旧入口未互相代替。
catalog.json的render_jobs列出已实际渲染的配方与当前输出目录。批量重跑需新目录，不能覆盖已有输出。
输出request/recipe/final/preview/renderer由receipt绑定；可迁移仓库位置，不需要generated缓存即可gate。
renderer记录实际输入alpha统计、中文字体和节点顺序；checkerboard内容、光照自然度和辨识度仍需看图，不用alpha统计冒充美术判断。
历史material-studies/与material-library-v1下的首轮根目录输出留作调试证据，当前有效输出仅catalog列出的r2目录。
