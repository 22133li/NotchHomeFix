# NotchHomeFix 复刻总账

目标：NotchHome 0.5.0；iOS 15.4、iPhone 13 Pro Max、RootHide。完整复刻按行为兼容定义，不要求逐行复制。状态只使用约定状态集。

| 模块 | 子功能 | 入口/触发方式 | 依赖 | 配置键 | 数据读写 | 事件/生命周期 | 错误分支 | 边界行为 | 兼容要求 | 当前状态 | 验收用例 | 证据 | 缺口 | 下轮动作 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 包安装 | 包标识、依赖、架构、安装关系 | 安装/升级/卸载 | MobileSubstrate、RootHide | 无 | deb 元数据 | 安装、升级、移除 | 包管理失败未知 | arm64e/rootless | 安装升级卸载不残留 Hook | 分析中 | 设备上安装/升级/卸载 | 原包 control | 设备包管理路径未测 | 核验包生命周期 |
| 注入范围 | SpringBoard filter | SpringBoard 启动 | RootHide 注入器 | 无 | 加载 dylib | 初始化/卸载 | filter/加载失败未知 | 仅 SpringBoard | 只注入目标进程 | 分析中 | 检查注入日志 | 原 plist 仅含 com.apple.springboard | 真机是否加载未知 | 真机确认注入 |
| 动画 API | 全屏回桌面修饰器 | App 关闭动画 | SpringBoard 私有类 | 无 | 方法参数/返回 | 动画计算 | 缺类/缺 selector/签名不匹配时跳过 Hook | 私有 ABI 版本差异 | 必须兼容签名校验和回退 | 分析中 | 对照 iOS 15.4 selector、签名和触发 | `hook-inventory.md`；frame slot `0x4f0` 调原 IMP 并写 CGRect/维护缓存；scale slot `0x4f8` 调原 IMP 并写 double | index 参数编码、精确 cache invalidation 与 scale 数值规则未完整解码 | 下一轮分析 frame 缓存更新条件和 scale 数值边界 |
| 手势动画 | 手势缩放动画属性 | 手势启动/关闭 App | 私有 switcher 类 | 无 | 动画属性 | 手势回调 | 缺类/属性行为未知 | 与点按路径不同 | 手势动画一致 | 分析中 | 手势入口黑盒对照 | `SBGestureInitiatedIconZoomAnimationAttributesSwitcherModifier` 字符串 | 调用逻辑未复原 | 追踪属性 Hook |
| 几何修复 | 图标 frame、圆角、bounds | 标准/手势动画属性计算 | `UIApplication`、`UIWindowScene`、SpringBoard window/controller、UIKit/CoreGraphics | 无 | container/candidate bounds、layout frame、icon/radius ivar、modifier cache、weak target | bounds/cache 命中复用；frame 分标准中心变换与特殊 aspect/clamp；corner slot closure 返回四个 double，精确回调语义待解 | 几何无效时 invalid zero CGRect 或对应原始结果回退 | `_homeScreenIconCornerRadius` 仅证实 ABI/offset 校验；已查路径未找到直接读取 | 目标图标 frame、圆角和失败回退兼容 | 分析中 | 核对 slot 0x500 的闭包捕获、返回值和 original IMP 路径 | `hook-inventory.md`；corner slot 返回 `{UIRectCornerRadii}` 四-double ABI | radii 算法、ivariable 的其他读取路径及真机黑盒未完成 | 下一轮继续解 corner slot closure 与 ivar 引用 |
| 透明度/匹配 | opacity、overlay、match move | 可见性 action/response | SpringBoard 私有事件 | 无 | action/response 对象 | 更新/响应次序 | nil/无响应未知 | 文件夹/Dock/多任务 | 可见状态和移动时序一致 | 分析中 | 动画前后可见性对照 | 相关 selector 字符串 | 回调 IMP、顺序待查 | 映射并复刻回调 |
| 转场生命周期 | begin/end/interruption | 动画开始/结束/中断 | modifier 实例 | 无 | 临时深度状态 | begin→end/interrupt | 重入/缺失 end 未知 | 连续动画、中断 | 退出后状态清理 | 待验证 | 连续触发与中断 | 原 selector；当前工程关联对象实现 | 原状态机语义未完全还原 | 与目标设备对照 |
| 非主屏幕修复 | 主屏、文件夹、Dock、资源库、搜索入口 | 从各入口启动 App 后返回 | 私有布局/目标 icon | 无 | 来源布局和目标几何 | 修复轨 | 错目标的回退行为未知 | 入口布局分别变化 | 与原包动画一致且都修复 | 不兼容 | 同设备逐入口录像对照 | `startedAtHome`、`_isEffectivelyHome`、`_isIndexZoomAppLayout:` 门槛 | 实验代码不能证明修复有效 | 建立来源分组并逆向目标选择 |
| 配置/停用 | enabled 偏好与原停用标记 | 进程初始化 | Foundation、RootHide 路径 | 原标记文件；新包 enabled | 原包启动读取文件存在性；新包另读 plist | 启动时采样；新包偏好可热加载 | 读取异常需真机确认 | 标记初始化后改动是否即时生效未知 | 原标记存在时停用 | 待验证 | 标记不存在/存在；启动后创建/删除分别测 | 原二进制固定路径及 `fileExistsAtPath:`；本轮加入启动时检查 | 未编译、未验证路径可达性和错误行为 | 在设备上执行三组用例 |
| 数据格式 | 偏好/缓存序列化 | 启动及动画 | Foundation/Swift | 新包 `enabled`，原键未知 | 原包持久格式未知；缓存字段已见 | 读取/缓存更新 | 解码失败未知 | 缺字段、空值、旧版本 | 配置与数据兼容 | 未开始 | 缺省/损坏/旧数据对照 | 字符串、类型编码 | 原配置 schema 未找全 | 追踪所有读写 |
| 错误/日志 | 错误行为、日志关键字段 | 异常/类型转换失败 | Swift/Foundation | 无 | 日志/错误 | 失败回退 | 存在 Swift fatal 文本，触发点未知 | 缺类、nil、签名不同 | 错误语义、关键字段兼容 | 未开始 | 缺类、错误对象、空输入 | strings 有 fatal 文本 | 日志字段/错误码不明 | 反汇编失败分支 |
| 缓存/并发 | frame bounds 与目标窗口缓存 | `frameForIndex:` 动画回调 | CGRect、weak target window | 无 | `containerViewBounds`、validity flag、weak target | bounds 完全相等且目标仍活着则复用；否则清缓存并重算 | bounds getter 缺失/CGRect 无效/重算失败则 invalid zero CGRect | 中断后 cache/target 清理待结合 lifecycle 验证 | bounds 比较和弱引用生命周期与原包一致 | 分析中 | bounds 相同复用；bounds 改变重算；target dealloc 重算；异常返回零矩形 | `hook-inventory.md`；CGRectEqualToRect、weak load/store、cache flags 的反汇编控制流 | 目标窗口过滤与 frame 计算 helper 仍需还原 | 下一轮追踪 SBMainSwitcherWindow/SBHomeScreenWindow 的选择规则 |
| 权限/外部行为 | sysctl、文件、网络 | 初始化/运行 | sysctl、文件管理器 | 无 | 设备型号和标记读取 | 初始化 | API 失败分支待查 | RootHide 路径差异 | 不增添权限副作用 | 分析中 | 缺文件/不可读测试 | 导入符号及路径字符串 | 动态解析尚未穷尽 | 检查全量外部调用 |
| 平台差异 | iOS 15.4/A15/arm64e/RootHide | 加载和运行 | 私有 ABI、PAC、编译器 | 无 | 无 | 每次系统启动 | selector 不匹配/加载失败 | RootHide scheme 和路径 | 稳定加载 | 待验证 | 目标设备加载、重启测试 | 包 arm64e；用户提供环境 | 没有设备验证 | CI 后再真机测 |
| 国际化/UI | 设置界面、语言 | 设置入口 | PreferenceLoader 等 | 原配置未知 | UI 配置读写 | UI 生命周期 | UI 缺失未知 | 多语言 | 若存在则兼容 | 分析中 | 检查资源、界面、strings | deb 仅列 dylib 与 filter | 尚不知是否外部设置工具 | 扫描全包与字符串 |
| 发布构建 | Theos/RootHide CI | GitHub Actions | macOS/Xcode/SDK/Theos | CI build number | deb artifact | CI build/release | compile/sign 失败 | iOS SDK vs target | 可安装 arm64e RootHide 包 | 阻塞 | GitHub Actions 成功并审包 | workflow 静态存在 | 本地无 THEOS；未连接 GitHub | 上传远端后运行 |
| 黑盒验收 | 动画对照/安装路径 | 主屏及每个来源入口 | 原包、新包、目标设备 | 所有 | 录像/日志/状态 | 安装→加载→转场→卸载 | 崩溃/回退 | 中断、重入、方向和边缘输入 | 输出差异可解释；无遗漏 | 未开始 | 主屏/文件夹/Dock/App Library/搜索逐项对照 | 目前无设备结果 | 无可用新包和日志 | 收集基线再验收 |

## 本轮记录

- 最小缺口：原插件停用标记的启动语义。
- 修复轨：新增启动时对原路径的 `fileExistsAtPath:` 检查，并将存在标记解释为禁用；不改变转场 Hook。
- 复刻轨：表中“配置/停用”更新为待验证；其余项未变。
- 静态验证：工程 doctor 通过。未编译、未运行、未做设备黑盒测试。
- 覆盖率：已兼容 0/16（0%）；待验证和分析中项目不计为兼容。
