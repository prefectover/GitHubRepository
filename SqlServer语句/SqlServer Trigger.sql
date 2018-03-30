--开启所有服务器配置
sp_configure 'show advanced options', 1;
GO
RECONFIGURE WITH OVERRIDE
GO
--开启CLR
sp_configure 'clr enabled', 1
GO
RECONFIGURE WITH OVERRIDE
GO
--关闭所有服务器配置
sp_configure 'show advanced options', 0; 
RECONFIGURE WITH override 
GO 
--关闭 CLR
sp_configure 'clr enabled', 0; 
RECONFIGURE WITH override 
GO

--权限不够时，设置目标数据库为可信赖的，例如：Test
ALTER DATABASE [Test] SET TRUSTWORTHY ON 

--修改数据库所有者为当前登录的用户，也可以为其他用户，例如：sa
EXEC sp_changedbowner 'sa'

--注册CLR程序集方式一，指定程序集DLL的路径
USE Test 
GO 
CREATE ASSEMBLY UserDefinedClrAssembly 
--AUTHORIZATION sa        --指定数据库所有者，默认为当前用户
FROM 'C:\Users\Administrator\Desktop\CLR Assembly\UserDefinedSqlClr.dll'        --指定文件路径
WITH PERMISSION_SET = UNSAFE;        --指定程序集的权限
                                --SAFE：无法访问外部系统资源；
                                --EXTERNAL_ACCESS：可以访问某些外部系统资源；
                                --UNSAFE：可以不受限制的访问外部系统资源
GO

--注册CLR程序集方式二，指定程序集DLL的16进制文件流
USE Test 
GO 
CREATE ASSEMBLY UserDefinedClrAssembly 
--AUTHORIZATION sa        --指定数据库所有者，默认为当前用户
FROM 0x4D5A90000300000004000000FFFF0000B8000000000000004000000000    --指定DLL的16进制文件流(当然没这么少，我删掉了)
WITH PERMISSION_SET = UNSAFE;        --指定程序集的权限
                                --SAFE：无法访问外部系统资源；
                                --EXTERNAL_ACCESS：可以访问某些外部系统资源；
                                --UNSAFE：可以不受限制的访问外部系统资源
GO 

USE Test 
GO 
--注册标量函数 ConvertToHexadecimal 
CREATE FUNCTION [dbo].[ConvertToHexadecimal](@strNumber NVARCHAR(128))
RETURNS NVARCHAR(128) 
WITH EXECUTE AS CALLER        --用于在用户在执行函数的时候对引用的对象进行权限检查
AS 
EXTERNAL NAME [UserDefinedClrAssembly].[UserDefinedFunctions].[ConvertToHexadecimal]    --EXTERNAL NAME 程序集名.类名.方法名
GO 

--注册触发器 FirstSqlTrigger
CREATE TRIGGER [FirstSqlTrigger] 
ON StudentInfo    --目标表
FOR INSERT,UPDATE,DELETE        --指定触发的操作
AS 
EXTERNAL NAME [UserDefinedSqlClr].[Triggers].[FirstSqlTrigger];    --EXTERNAL NAME 程序集名.类名.方法名
GO

--删除聚合函数 SumString 
DROP FUNCTION dbo.SumString

--删除程序集 UserDefinedClrAssembly 
DROP ASSEMBLY UserDefinedClrAssembly

--删除数据库级别触发器 SecondSqlTrigger
drop trigger [SecondSqlTrigger] on database
------------------------------------------

USE TestDatabase 
GO 
CREATE ASSEMBLY UserDefinedClrAssembly 
--AUTHORIZATION sa 
FROM 'D:\GitHubAssets\TestVSProject\TestTrigger\TestTrigger\bin\Debug\TestTrigger.dll'
WITH PERMISSION_SET = SAFE;
GO

DROP ASSEMBLY UserDefinedClrAssembly

CREATE TRIGGER FirstSqlTrigger
ON Student    --目标表
FOR INSERT,UPDATE,DELETE        --指定触发的操作
AS                              --如果程序集里有命名空间 则"命名空间.类名"(不能用单引号),无则: 直接类名
EXTERNAL NAME UserDefinedClrAssembly."TestTrigger.Class2".UF_DML_Trigger;
GO

INSERT INTO Student VALUES (9, 'liutao');
INSERT INTO Student VALUES (10, 'liujie');

SELECT * FROM student;