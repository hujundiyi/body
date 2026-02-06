# Weeder 应用架构文档

## 概述

本项目基于 GetX 构建了一个完整的 Flutter 应用架构，采用分层设计模式，提供了状态管理、路由管理、网络请求、本地存储等功能。

## 架构特点

- **GetX 状态管理**: 响应式状态管理，自动更新UI
- **分层架构**: 清晰的分层结构，职责分离
- **依赖注入**: 使用 GetX 的依赖注入系统
- **路由管理**: 声明式路由配置
- **错误处理**: 统一的错误处理机制
- **日志系统**: 完整的日志记录
- **数据验证**: 表单验证工具

## 项目结构

```
lib/
├── app/                    # 应用层
│   ├── controllers/        # 控制器
│   ├── pages/             # 页面
│   ├── views/             # 视图组件
│   └── widgets/           # 通用组件
├── core/                  # 核心层
│   ├── base/              # 基础类
│   ├── constants/         # 常量
│   ├── services/          # 服务
│   ├── theme/             # 主题
│   └── utils/             # 工具类
├── data/                  # 数据层
│   ├── models/            # 数据模型
│   ├── repositories/      # 仓库
│   └── providers/         # 数据提供者
└── routes/                # 路由
    ├── app_pages.dart     # 路由配置
    └── app_routes.dart    # 路由定义
```

## 核心组件

### 1. 基础控制器 (BaseController)

提供通用的状态管理和生命周期方法：

```dart
abstract class BaseController extends GetxController {
  // 加载状态
  final RxBool _isLoading = false.obs;
  
  // 错误状态
  final RxString _errorMessage = ''.obs;
  
  // 通用方法
  void setLoading(bool loading);
  void setError(String error);
  Future<T?> executeWithLoading<T>(Future<T> Function() operation);
}
```

### 2. 基础仓库 (BaseRepository)

提供网络请求的通用方法：

```dart
abstract class BaseRepository {
  // HTTP 方法
  Future<Response<T>> get<T>(String path);
  Future<Response<T>> post<T>(String path, {dynamic data});
  Future<Response<T>> put<T>(String path, {dynamic data});
  Future<Response<T>> delete<T>(String path, {dynamic data});
}
```

### 3. 服务层

#### 存储服务 (StorageService)
- 基于 SharedPreferences 的本地存储
- 支持各种数据类型存储

#### API服务 (ApiService)
- 基于 Dio 的网络请求
- 统一的错误处理
- 请求/响应拦截器

#### 认证服务 (AuthService)
- 用户认证状态管理
- Token 管理
- 自动登录检查

### 4. 路由管理

#### 路由定义 (AppRoutes)
```dart
class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/home';
  
  static final List<GetPage> routes = [
    GetPage(name: splash, page: () => const SplashPage()),
    GetPage(name: home, page: () => const HomePage()),
  ];
}
```

#### 路由跳转
```dart
// 跳转到指定页面
AppRoutes.toNamed(AppRoutes.home);

// 替换当前页面
AppRoutes.offNamed(AppRoutes.home);

// 清空路由栈并跳转
AppRoutes.offAllNamed(AppRoutes.home);
```

## 使用指南

### 1. 创建控制器

```dart
class HomeController extends BaseController {
  final RxInt counter = 0.obs;
  
  void increment() {
    counter.value++;
  }
  
  @override
  void onControllerReady() {
    super.onControllerReady();
    // 初始化逻辑
  }
}
```

### 2. 创建页面

```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    
    return Scaffold(
      body: Obx(() => Text('${controller.counter}')),
    );
  }
}
```

### 3. 网络请求

```dart
class UserRepository extends BaseRepository {
  Future<Response> getUserInfo() async {
    return await get('/user/info');
  }
}
```

### 4. 数据模型

```dart
@JsonSerializable()
class UserModel {
  final int id;
  final String username;
  final String email;
  
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

## 最佳实践

### 1. 控制器使用
- 继承 `BaseController` 获得通用功能
- 使用 `Obx` 包装需要响应式更新的 Widget
- 在 `onControllerReady` 中执行初始化逻辑

### 2. 状态管理
- 使用 `Rx` 类型定义响应式变量
- 避免在 `build` 方法中创建新的对象
- 合理使用 `GetBuilder` 和 `Obx`

### 3. 路由管理
- 在 `AppRoutes` 中定义所有路由
- 使用命名路由进行页面跳转
- 合理设置页面转场动画

### 4. 错误处理
- 使用 `executeWithLoading` 包装异步操作
- 统一处理网络错误和业务错误
- 提供用户友好的错误提示

### 5. 数据验证
- 使用 `Validators` 类进行表单验证
- 在提交前进行完整的数据验证
- 提供清晰的错误提示信息

## 扩展功能

### 1. 添加新页面
1. 在 `app/pages/` 中创建页面文件
2. 在 `app/controllers/` 中创建控制器
3. 在 `AppRoutes` 中添加路由定义
4. 在 `AppPages` 中注册路由

### 2. 添加新服务
1. 在 `core/services/` 中创建服务文件
2. 在 `main.dart` 的 `_initServices` 中注册服务
3. 使用 `Get.find<ServiceName>()` 获取服务实例

### 3. 添加新数据模型
1. 在 `data/models/` 中创建模型文件
2. 使用 `json_annotation` 注解
3. 运行 `flutter packages pub run build_runner build` 生成代码

## 依赖包

- `get`: GetX 状态管理框架
- `dio`: 网络请求库
- `shared_preferences`: 本地存储
- `json_annotation`: JSON 序列化注解
- `json_serializable`: JSON 序列化代码生成
- `build_runner`: 代码生成工具

## 总结

这个架构提供了一个完整的、可扩展的 Flutter 应用基础框架。通过分层设计和 GetX 的强大功能，可以快速开发出高质量的移动应用。架构具有良好的可维护性和可测试性，适合中大型项目的开发。
