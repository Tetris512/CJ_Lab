## 一、代码结构与设计

### 1. 变量的管理

![image-20251106164746486](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106164746486.png)

使用对象Binding,其四个枚举值分别对应LET未初始化变量、VAR未初始化变量、LET初始化对象、VAR初始化对象，方便处理之后的赋值语句和变量声明语句。

![image-20251106164959637](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106164959637.png)

在变量声明语句中，即使没有赋值，UIninitiated也会存储各种类型的默认值，这样之后赋值的时候便可以确认其是否定义了固定的类型



### 2. 作用域的管理

![image-20251106165416972](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106165416972.png)

用context表示当前所处的作用域，用static_scope表示所定义的所有的作用域，用Environment的enclosing便可以从当前的context向上遍历到所有父作用域



### 3. 跳转语句的实现

![image-20251106165644506](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106165644506.png)

用全局变量loopDepth记录当前所处嵌套深度，在访问while语句的时候对其值进行修改

![image-20251106165741032](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106165741032.png)

定义两个Exception用于实现break和continue的跳转，其中continue只需要打断并继续重新循环即可，break则需要直接跳出循环。

![image-20251106165808204](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106165808204.png)



### 4. 工具函数的实现

①判断TypeNode所处的类型

![image-20251106170038066](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106170038066.png)

② 判断TypeNode与Value是否类型相同

![image-20251106170129632](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106170129632.png)

③判断if语句是否有else分支

![image-20251106170207391](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106170207391.png)

④ 递归向上覆盖最早的定义name的变量，将值修改为Binding，用于处理赋值语句

![image-20251106170251587](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106170251587.png)

⑤一些简单的逻辑判断函数

![image-20251106170341028](C:\Users\Administrator\AppData\Roaming\Typora\typora-user-images\image-20251106170341028.png)





## 二、遇到的困难与解决方案

#### 1. 如何确定一个变量是否已经赋值、是否已经定义类型、是否只能赋值一次

解决方案：定义binding类型来区分不同类型变量



#### 2. 如何处理continue和break的跳转逻辑

解决方案：定义新的Exception来实现中断退出，遇到continue和break都抛出Exception



#### 3. 如何确定一个VarDecl是否有确定固定的类型

解决方案：实现getAnnotatedTypeName来获取TypeNode的对应类型







## 三、 已知BUG

暂时没有