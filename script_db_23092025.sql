USE [CirroDb]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_CalculateDistanceFromRSSI]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- UTILITY FUNCTIONS (CORRECTED SYNTAX)
-- =============================================

-- Function to calculate distance from signal strength
CREATE   FUNCTION [dbo].[fn_CalculateDistanceFromRSSI]
(
    @RSSI INT,
    @TxPower INT = -59
)
RETURNS DECIMAL(5,2)
AS
BEGIN
    DECLARE @Distance DECIMAL(5,2)
    
    IF @RSSI = 0
        SET @Distance = -1.0
    ELSE
        SET @Distance = POWER(10.0, (@TxPower - @RSSI) / 20.0)
    
    RETURN @Distance
END;

GO
/****** Object:  Table [dbo].[WorkSchedule]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkSchedule](
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NULL,
	[DepartmentID] [int] NULL,
	[BranchID] [int] NULL,
	[ScheduleName] [nvarchar](100) NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[BreakStartTime] [time](7) NULL,
	[BreakEndTime] [time](7) NULL,
	[WorkingDays] [nvarchar](20) NOT NULL,
	[IsFlexible] [bit] NOT NULL,
	[FlexibleStartWindow] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK_WorkSchedule] PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Employee]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee](
	[EmployeeID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyID] [int] NOT NULL,
	[BranchID] [int] NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[EmployeeCode] [nvarchar](50) NOT NULL,
	[FirstNameAr] [nvarchar](100) NOT NULL,
	[LastNameAr] [nvarchar](100) NOT NULL,
	[FirstNameEn] [nvarchar](100) NULL,
	[LastNameEn] [nvarchar](100) NULL,
	[Email] [nvarchar](100) NULL,
	[Phone] [nvarchar](50) NULL,
	[HireDate] [date] NOT NULL,
	[Status] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate1] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__Employee__7AD04FF1CC484A8A] PRIMARY KEY CLUSTERED 
(
	[EmployeeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetEmployeeWorkSchedule]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Function to get employee work schedule
CREATE   FUNCTION [dbo].[fn_GetEmployeeWorkSchedule]
(
    @EmployeeID INT,
    @WorkDate DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1 
        ws.ScheduleID,
        ws.StartTime,
        ws.EndTime,
        ws.BreakStartTime,
        ws.BreakEndTime,
        ws.IsFlexible,
        ws.FlexibleStartWindow
    FROM WorkSchedule ws
    INNER JOIN Employee e ON ws.EmployeeID = e.EmployeeID OR ws.EmployeeID IS NULL
    WHERE (ws.EmployeeID = @EmployeeID OR ws.EmployeeID IS NULL)
      AND (ws.DepartmentID = e.DepartmentID OR ws.DepartmentID IS NULL)
      AND (ws.BranchID = e.BranchID OR ws.BranchID IS NULL)
      AND ws.IsActive = 1
      AND (ws.WorkingDays LIKE '%' + CAST(DATEPART(WEEKDAY, @WorkDate) AS VARCHAR) + '%' 
           OR ws.WorkingDays IS NULL)
    ORDER BY 
        CASE WHEN ws.EmployeeID IS NOT NULL THEN 1 ELSE 2 END,
        CASE WHEN ws.DepartmentID IS NOT NULL THEN 1 ELSE 2 END
);

GO
/****** Object:  Table [dbo].[AttendanceAuditLog]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AttendanceAuditLog](
	[AuditID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[AttendanceID] [bigint] NULL,
	[Action] [nvarchar](50) NOT NULL,
	[OldValue] [nvarchar](max) NULL,
	[NewValue] [nvarchar](max) NULL,
	[ActionBy] [nvarchar](100) NULL,
	[ActionTime] [datetime] NOT NULL,
	[Reason] [nvarchar](500) NULL,
	[IPAddress] [nvarchar](50) NULL,
 CONSTRAINT [PK_AttendanceAuditLog] PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AttendanceRules]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AttendanceRules](
	[RuleID] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [nvarchar](100) NOT NULL,
	[RuleType] [nvarchar](50) NOT NULL,
	[ThresholdMinutes] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK_AttendanceRules] PRIMARY KEY CLUSTERED 
(
	[RuleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BeaconConfiguration]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BeaconConfiguration](
	[ConfigID] [int] IDENTITY(1,1) NOT NULL,
	[DeviceID] [int] NOT NULL,
	[DetectionThreshold] [int] NOT NULL,
	[EnterRange] [int] NOT NULL,
	[ExitRange] [int] NOT NULL,
	[ScanInterval] [int] NOT NULL,
	[IsAutoPunchIn] [bit] NOT NULL,
	[IsAutoPunchOut] [bit] NOT NULL,
	[AutoPunchOutDelay] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK_BeaconConfiguration] PRIMARY KEY CLUSTERED 
(
	[ConfigID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BeaconEvents]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BeaconEvents](
	[EventID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[DeviceID] [int] NOT NULL,
	[EventType] [nvarchar](20) NOT NULL,
	[SignalStrength] [int] NOT NULL,
	[Distance] [decimal](5, 2) NULL,
	[EventTime] [datetime] NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[ProcessedTime] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BeaconEvents] PRIMARY KEY CLUSTERED 
(
	[EventID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BeaconProximityTracking]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BeaconProximityTracking](
	[TrackingID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[DeviceID] [int] NOT NULL,
	[EnterTime] [datetime] NOT NULL,
	[ExitTime] [datetime] NULL,
	[DurationMinutes] [int] NULL,
	[MaxSignalStrength] [int] NOT NULL,
	[MinSignalStrength] [int] NOT NULL,
	[AverageSignalStrength] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
 CONSTRAINT [PK_BeaconProximityTracking] PRIMARY KEY CLUSTERED 
(
	[TrackingID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BioMetricType]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BioMetricType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[NameAr] [nvarchar](50) NULL,
	[NameEn] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK_BioMetricType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Branch]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Branch](
	[BranchID] [int] IDENTITY(1,1) NOT NULL,
	[CompanyID] [int] NOT NULL,
	[NameAr] [nvarchar](200) NULL,
	[NameEn] [nvarchar](200) NULL,
	[Address] [nvarchar](300) NULL,
	[Phone] [nvarchar](50) NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK__Branch__A1682FA5748AF6A2] PRIMARY KEY CLUSTERED 
(
	[BranchID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BranchDevice]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BranchDevice](
	[DeviceID] [int] IDENTITY(1,1) NOT NULL,
	[LocationID] [int] NOT NULL,
	[DeviceUUID] [nvarchar](100) NOT NULL,
	[Major] [int] NOT NULL,
	[Minor] [int] NOT NULL,
	[NameAr] [nvarchar](200) NULL,
	[NameEn] [nvarchar](200) NULL,
	[Status] [bit] NULL,
	[InstalledDate] [datetime] NULL,
	[DeviceTypeID] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[BeaconUUID] [nvarchar](36) NULL,
	[SignalStrength] [int] NULL,
	[DetectionRange] [nvarchar](20) NULL,
	[LastSeen] [datetime] NULL,
	[BatteryLevel] [int] NULL,
	[FirmwareVersion] [nvarchar](50) NULL,
	[CalibrationDistance] [decimal](5, 2) NULL,
	[IsBeaconEnabled] [bit] NOT NULL,
 CONSTRAINT [PK__BranchDe__49E12331F888D50C] PRIMARY KEY CLUSTERED 
(
	[DeviceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BranchLocation]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BranchLocation](
	[LocationID] [int] IDENTITY(1,1) NOT NULL,
	[BranchID] [int] NOT NULL,
	[NameAr] [nvarchar](200) NULL,
	[NameEn] [nvarchar](200) NULL,
	[Floor] [nvarchar](50) NULL,
	[Room] [nvarchar](100) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__BranchLo__E7FEA4770783B989] PRIMARY KEY CLUSTERED 
(
	[LocationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Company]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Company](
	[CompanyID] [int] IDENTITY(1,1) NOT NULL,
	[NameAr] [nvarchar](200) NULL,
	[NameEn] [nvarchar](200) NULL,
	[Address] [nvarchar](300) NULL,
	[Phone] [nvarchar](50) NULL,
	[Email] [nvarchar](100) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate1] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__Company__2D971C4C2E066259] PRIMARY KEY CLUSTERED 
(
	[CompanyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Department]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Department](
	[DepartmentID] [int] IDENTITY(1,1) NOT NULL,
	[BranchID] [int] NOT NULL,
	[NameAr] [nvarchar](200) NULL,
	[NameEn] [nvarchar](200) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__Departme__B2079BCD98628D9A] PRIMARY KEY CLUSTERED 
(
	[DepartmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DeviceType]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeviceType](
	[DeviceTypeID] [int] IDENTITY(1,1) NOT NULL,
	[NameAr] [nvarchar](50) NULL,
	[NameEn] [nvarchar](50) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate1] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__DeviceTy__07A6C71633635D31] PRIMARY KEY CLUSTERED 
(
	[DeviceTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeBeaconRegistration]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeBeaconRegistration](
	[RegistrationID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[DeviceID] [int] NOT NULL,
	[RegistrationDate] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LastSeen] [datetime] NULL,
	[TotalVisits] [int] NOT NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK_EmployeeBeaconRegistration] PRIMARY KEY CLUSTERED 
(
	[RegistrationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeBioMetric]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeBioMetric](
	[BioMetricID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[BioMetricTypeId] [int] NOT NULL,
	[BioMetricData] [varbinary](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedDate1] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
 CONSTRAINT [PK__Employee__B6ADD0C17AA645FF] PRIMARY KEY CLUSTERED 
(
	[BioMetricID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmployeeCheckInOut]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeeCheckInOut](
	[AttendanceID] [bigint] IDENTITY(1,1) NOT NULL,
	[EmployeeID] [int] NOT NULL,
	[DeviceID] [int] NOT NULL,
	[CheckInTime] [datetime] NULL,
	[CheckOutTime] [datetime] NULL,
	[WorkDate] [date] NOT NULL,
	[Status] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [nvarchar](100) NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[AutoPunchIn] [bit] NOT NULL,
	[AutoPunchOut] [bit] NOT NULL,
	[LastBeaconSeen] [datetime] NULL,
	[TotalBeaconEvents] [int] NOT NULL,
	[WorkHours] [decimal](5, 2) NULL,
	[OvertimeHours] [decimal](5, 2) NULL,
	[IsLate] [bit] NOT NULL,
	[IsEarlyDeparture] [bit] NOT NULL,
	[AttendanceStatus] [nvarchar](50) NULL,
	[Notes] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[AttendanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[RoleId] [int] IDENTITY(1,1) NOT NULL,
	[NameAr] [nvarchar](50) NOT NULL,
	[NameEn] [nvarchar](50) NOT NULL,
	[CreatedBy] [nvarchar](100) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RoleMember]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoleMember](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RoleId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[CreatedBy] [nvarchar](100) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_RoleMember] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[User]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[NameAr] [nvarchar](50) NOT NULL,
	[NameEn] [nvarchar](50) NOT NULL,
	[LoginName] [nvarchar](50) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[CreatedBy] [nvarchar](100) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[ModifiedBy] [nvarchar](100) NULL,
	[ModificationDate] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[AttendanceRules] ON 
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (1, N'تأخير بسيط', N'Late Arrival', 5, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (2, N'تأخير معتدل', N'Late Arrival', 10, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (3, N'تأخير متوسط', N'Late Arrival', 15, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (4, N'تأخير كبير', N'Late Arrival', 30, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (5, N'تأخير شديد', N'Late Arrival', 60, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (6, N'انصراف مبكر بسيط', N'Early Leave', 5, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (7, N'انصراف مبكر متوسط', N'Early Leave', 15, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (8, N'انصراف مبكر شديد', N'Early Leave', 30, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (9, N'غياب بدون عذر', N'Absence', 480, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (10, N'غياب يوم كامل', N'Absence', 1440, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (11, N'تجاوز استراحة الغداء', N'Break Overstay', 30, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (12, N'تأخير العودة من الاستراحة', N'Break Overstay', 15, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (13, N'تأخير تسجيل الدخول', N'Missed Check-In', 120, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (14, N'تأخير تسجيل الخروج', N'Missed Check-Out', 120, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[AttendanceRules] ([RuleID], [RuleName], [RuleType], [ThresholdMinutes], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (15, N'حضور غير مكتمل', N'Incomplete Attendance', 240, 1, N'System', CAST(N'2025-09-12T03:03:56.960' AS DateTime), NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[AttendanceRules] OFF
GO
SET IDENTITY_INSERT [dbo].[BioMetricType] ON 
GO
INSERT [dbo].[BioMetricType] ([Id], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (1, N'بصمة الوجه', N'Face ID', 1, N'System', NULL, NULL, NULL)
GO
INSERT [dbo].[BioMetricType] ([Id], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (2, N'بصمة الإصبع', N'Fingerprint', 1, N'System', NULL, NULL, NULL)
GO
INSERT [dbo].[BioMetricType] ([Id], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (3, N'بصمة الصوت', N'Voice Recognition', 1, N'System', NULL, NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[BioMetricType] OFF
GO
SET IDENTITY_INSERT [dbo].[Branch] ON 
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (1, 1, N'فرع الرياض', N'Riyadh Branch', N'Olaya St, Riyadh', N'+966-555200001', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (2, 1, N'فرع الدمام', N'Dammam Branch', N'King Fahd Rd, Dammam', N'+966-555200002', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (3, 2, N'فرع جدة', N'Jeddah Branch', N'Corniche, Jeddah', N'+966-555200003', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (4, 2, N'فرع المدينة', N'Madinah Branch', N'Uhud Rd, Madinah', N'+966-555200004', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (5, 3, N'فرع الخبر', N'Khobar Branch', N'Corniche, Khobar', N'+966-555200005', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (6, 3, N'فرع ينبع', N'Yanbu Branch', N'Industrial Area, Yanbu', N'+966-555200006', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (7, 4, N'فرع مكة', N'Mecca Branch', N'Haram Rd, Mecca', N'+966-555200007', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (8, 4, N'فرع الطائف', N'Taif Branch', N'Shada St, Taif', N'+966-555200008', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (9, 5, N'فرع القصيم', N'Qassim Branch', N'King Abdulaziz Rd, Qassim', N'+966-555200009', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (10, 6, N'فرع أبها', N'Abha Branch', N'Airport Rd, Abha', N'+966-555200010', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (11, 7, N'فرع حائل', N'Hail Branch', N'Salam St, Hail', N'+966-555200011', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (12, 8, N'فرع تبوك', N'Tabuk Branch', N'King Khalid Rd, Tabuk', N'+966-555200012', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (13, 9, N'فرع جيزان', N'Jizan Branch', N'Corniche, Jizan', N'+966-555200013', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (14, 10, N'فرع الباحة', N'Al Bahah Branch', N'Main Rd, Al Bahah', N'+966-555200014', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:52:52.643' AS DateTime), 1)
GO
INSERT [dbo].[Branch] ([BranchID], [CompanyID], [NameAr], [NameEn], [Address], [Phone], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (15, 10, N'فرع سكاكا', N'Sakaka Branch', N'Center Rd, Sakaka', N'+966-555200015', N'System', CAST(N'2025-09-12T03:03:56.930' AS DateTime), N'w.aldahin', CAST(N'2025-09-22T19:46:46.140' AS DateTime), 1)
GO
SET IDENTITY_INSERT [dbo].[Branch] OFF
GO
SET IDENTITY_INSERT [dbo].[Company] ON 
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (1, N'شركة التقنية', N'Tech Corp', N'Riyadh, KSA', N'+966-555111001', N'info@techcorp.com', 1, NULL, N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T20:32:07.200' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (2, N'شركة المستقبل', N'Future Solutions', N'Jeddah, KSA', N'+966-555111002', N'contact@future.com', 1, CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (3, N'شركة العالمية', N'Global Systems', N'Dammam, KSA', N'+966-555111003', N'global@systems.com', 1, CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (4, N'شركة البناء 123', N'BuildCo 123', N'Khobar, KSA', N'+966-555111004', N'info@buildco.com', 1, NULL, N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T20:26:15.057' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (5, N'شركة الصحة', N'HealthCare Inc.', N'Madinah, KSA', N'+966-555111005', N'contact@healthcare.com', 1, CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (6, N'شركة الطاقة', N'Energy Solutions', N'Tabuk, KSA', N'+966-555111006', N'energy@solutions.com', 1, CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (7, N'شركة الاتصالات', N'TeleCom Arabia', N'Abha, KSA', N'+966-555111007', N'tele@arabia.com', 1, NULL, N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:11:39.027' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (8, N'شركة التعليم', N'Edutech', N'Mecca, KSA', N'+966-555111008', N'edu@edutech.com', 1, CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (9, N'شركة النقل', N'TransLog', N'Yanbu, KSA', N'+966-555111009', N'trans@log.com', 1, NULL, N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:11:37.377' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (10, N'شركة التسويق', N'MarketingPro', N'Jizan, KSA', N'+966-555111010', N'marketing@pro.com', 1, NULL, N'System', CAST(N'2025-09-12T03:03:56.913' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:29:30.437' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (11, N'AAA', N'ASD', NULL, N'12343212343', N'www@sss.com', 1, NULL, N'admin', CAST(N'2025-09-18T21:33:43.427' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:37:58.687' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (12, N'شيشسي ي', N'AAA', N'sdsadsadas', N'232332423', N'sss@sss.com', 1, NULL, N'w.aldahin', CAST(N'2025-09-20T20:52:47.947' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:47:20.450' AS DateTime))
GO
INSERT [dbo].[Company] ([CompanyID], [NameAr], [NameEn], [Address], [Phone], [Email], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (13, N'لبي بلبيل', N'AAA', N'Address', N'34234234', N'sss@ss.com', 1, NULL, N'w.aldahin', CAST(N'2025-09-20T21:01:45.433' AS DateTime), N'w.aldahin', CAST(N'2025-09-20T22:35:53.177' AS DateTime))
GO
SET IDENTITY_INSERT [dbo].[Company] OFF
GO
SET IDENTITY_INSERT [dbo].[Department] ON 
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (1, 1, N'الموارد البشرية', N'Human Resources', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (2, 1, N'تكنولوجيا المعلومات', N'IT Department', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (3, 2, N'المبيعات', N'Sales', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (4, 2, N'الدعم الفني', N'Technical Support', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (5, 3, N'المحاسبة', N'Accounting', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (6, 3, N'الخدمات', N'Services', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (7, 4, N'الموارد البشرية', N'HR', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (8, 5, N'الإدارة', N'Administration', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (9, 5, N'المبيعات', N'Sales', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (10, 6, N'خدمة العملاء', N'Customer Service', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (11, 7, N'الدعم', N'Support', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (12, 8, N'الموارد البشرية', N'HR', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (13, 9, N'التسويق', N'Marketing', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (14, 10, N'المبيعات', N'Sales', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (15, 11, N'الإنتاج', N'Production', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (16, 12, N'الجودة', N'Quality Assurance', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (17, 13, N'الأمن', N'Security', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (18, 14, N'الصيانة', N'Maintenance', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (19, 15, N'تكنولوجيا المعلومات', N'IT', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
INSERT [dbo].[Department] ([DepartmentID], [BranchID], [NameAr], [NameEn], [IsActive], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (20, 15, N'المالية', N'Finance', 1, N'System', CAST(N'2025-09-12T03:03:56.940' AS DateTime), NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[Department] OFF
GO
SET IDENTITY_INSERT [dbo].[DeviceType] ON 
GO
INSERT [dbo].[DeviceType] ([DeviceTypeID], [NameAr], [NameEn], [IsActive], [CreatedDate1], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate]) VALUES (1, N'جهاز Beacons', N'Beacons Device', 1, CAST(N'2025-09-12T03:03:56.943' AS DateTime), N'System', CAST(N'2025-09-12T03:03:56.943' AS DateTime), NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[DeviceType] OFF
GO
SET IDENTITY_INSERT [dbo].[Role] ON 
GO
INSERT [dbo].[Role] ([RoleId], [NameAr], [NameEn], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (1, N'مدير نظام', N'Admin', N'System', CAST(N'2025-01-01T00:00:00.000' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[Role] ([RoleId], [NameAr], [NameEn], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (2, N'موارد بشرية', N'HR', N'System', CAST(N'2025-01-01T00:00:00.000' AS DateTime), NULL, NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[Role] OFF
GO
SET IDENTITY_INSERT [dbo].[RoleMember] ON 
GO
INSERT [dbo].[RoleMember] ([Id], [RoleId], [UserId], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (1, 1, 1, N'System', CAST(N'2025-01-01T00:00:00.000' AS DateTime), NULL, NULL, 1)
GO
INSERT [dbo].[RoleMember] ([Id], [RoleId], [UserId], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (2, 2, 1, N'system', CAST(N'2025-09-14T20:48:48.480' AS DateTime), NULL, NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[RoleMember] OFF
GO
SET IDENTITY_INSERT [dbo].[User] ON 
GO
INSERT [dbo].[User] ([UserId], [NameAr], [NameEn], [LoginName], [Password], [CreatedBy], [CreationDate], [ModifiedBy], [ModificationDate], [IsActive]) VALUES (1, N'وسام الدحين', N'Wessam AlDahin', N'w.aldahin', N'V/23yOgDIKWfRt897U5PrAnPNtSYOTXCUBKLLNIgSkLVpdoL', N'string', CAST(N'2025-09-13T16:52:07.053' AS DateTime), NULL, NULL, 1)
GO
SET IDENTITY_INSERT [dbo].[User] OFF
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ__Employee__1F642548506C4C25]    Script Date: 9/23/2025 12:15:20 AM ******/
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [UQ__Employee__1F642548506C4C25] UNIQUE NONCLUSTERED 
(
	[EmployeeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AttendanceAuditLog] ADD  DEFAULT (getdate()) FOR [ActionTime]
GO
ALTER TABLE [dbo].[AttendanceRules] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[AttendanceRules] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((-70)) FOR [DetectionThreshold]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((-50)) FOR [EnterRange]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((-80)) FOR [ExitRange]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((5)) FOR [ScanInterval]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((1)) FOR [IsAutoPunchIn]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((1)) FOR [IsAutoPunchOut]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((30)) FOR [AutoPunchOutDelay]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BeaconConfiguration] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[BeaconEvents] ADD  DEFAULT (getdate()) FOR [EventTime]
GO
ALTER TABLE [dbo].[BeaconEvents] ADD  DEFAULT ((0)) FOR [IsProcessed]
GO
ALTER TABLE [dbo].[BeaconEvents] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[BeaconProximityTracking] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BeaconProximityTracking] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Branch] ADD  CONSTRAINT [DF__Branch__CreatedD__3B75D760]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  CONSTRAINT [DF__BranchDev__Statu__4316F928]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  CONSTRAINT [DF__BranchDev__Insta__440B1D61]  DEFAULT (getdate()) FOR [InstalledDate]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  CONSTRAINT [DF__BranchDev__Devic__619B8048]  DEFAULT ((1)) FOR [DeviceTypeID]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  CONSTRAINT [DF__BranchDev__IsAct__74AE54BC]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  CONSTRAINT [DF__BranchDev__Creat__73BA3083]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[BranchDevice] ADD  DEFAULT ((1)) FOR [IsBeaconEnabled]
GO
ALTER TABLE [dbo].[BranchLocation] ADD  CONSTRAINT [DF__BranchLoc__IsAct__72C60C4A]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[BranchLocation] ADD  CONSTRAINT [DF__BranchLoc__Creat__3F466844]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[BranchLocation] ADD  CONSTRAINT [DF__BranchLoc__Creat__71D1E811]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Company] ADD  CONSTRAINT [DF_Company_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Company] ADD  CONSTRAINT [DF_Company_CreatedDate1]  DEFAULT (getdate()) FOR [CreatedDate1]
GO
ALTER TABLE [dbo].[Company] ADD  CONSTRAINT [DF_Company_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Department] ADD  CONSTRAINT [DF_Department_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Department] ADD  CONSTRAINT [DF_Department_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[DeviceType] ADD  CONSTRAINT [DF_DeviceType_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[DeviceType] ADD  CONSTRAINT [DF_DeviceType_CreatedDate1]  DEFAULT (getdate()) FOR [CreatedDate1]
GO
ALTER TABLE [dbo].[DeviceType] ADD  CONSTRAINT [DF_DeviceType_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF__Employee__Status__4E88ABD4]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_CreatedDate1]  DEFAULT (getdate()) FOR [CreatedDate1]
GO
ALTER TABLE [dbo].[Employee] ADD  CONSTRAINT [DF_Employee_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] ADD  DEFAULT (getdate()) FOR [RegistrationDate]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] ADD  DEFAULT ((0)) FOR [TotalVisits]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[EmployeeBioMetric] ADD  CONSTRAINT [DF_EmployeeBioMetric_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmployeeBioMetric] ADD  CONSTRAINT [DF_EmployeeBioMetric_CreatedDate1]  DEFAULT (getdate()) FOR [CreatedDate1]
GO
ALTER TABLE [dbo].[EmployeeBioMetric] ADD  CONSTRAINT [DF_EmployeeBioMetric_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT (CONVERT([date],getdate())) FOR [WorkDate]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ('Present') FOR [Status]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((0)) FOR [AutoPunchIn]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((0)) FOR [AutoPunchOut]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((0)) FOR [TotalBeaconEvents]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((0)) FOR [IsLate]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] ADD  DEFAULT ((0)) FOR [IsEarlyDeparture]
GO
ALTER TABLE [dbo].[Role] ADD  CONSTRAINT [DF_Role_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[Role] ADD  CONSTRAINT [DF_Role_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RoleMember] ADD  CONSTRAINT [DF_RoleMember_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[RoleMember] ADD  CONSTRAINT [DF_RoleMember_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_Users_CreationDate]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[User] ADD  CONSTRAINT [DF_Users_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[WorkSchedule] ADD  DEFAULT ((0)) FOR [IsFlexible]
GO
ALTER TABLE [dbo].[WorkSchedule] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[WorkSchedule] ADD  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [dbo].[AttendanceAuditLog]  WITH CHECK ADD  CONSTRAINT [FK_AttendanceAuditLog_Employee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[AttendanceAuditLog] CHECK CONSTRAINT [FK_AttendanceAuditLog_Employee]
GO
ALTER TABLE [dbo].[AttendanceAuditLog]  WITH CHECK ADD  CONSTRAINT [FK_AttendanceAuditLog_EmployeeCheckInOut] FOREIGN KEY([AttendanceID])
REFERENCES [dbo].[EmployeeCheckInOut] ([AttendanceID])
GO
ALTER TABLE [dbo].[AttendanceAuditLog] CHECK CONSTRAINT [FK_AttendanceAuditLog_EmployeeCheckInOut]
GO
ALTER TABLE [dbo].[BeaconConfiguration]  WITH CHECK ADD  CONSTRAINT [FK_BeaconConfiguration_BranchDevice] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[BranchDevice] ([DeviceID])
GO
ALTER TABLE [dbo].[BeaconConfiguration] CHECK CONSTRAINT [FK_BeaconConfiguration_BranchDevice]
GO
ALTER TABLE [dbo].[BeaconEvents]  WITH CHECK ADD  CONSTRAINT [FK_BeaconEvents_BranchDevice] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[BranchDevice] ([DeviceID])
GO
ALTER TABLE [dbo].[BeaconEvents] CHECK CONSTRAINT [FK_BeaconEvents_BranchDevice]
GO
ALTER TABLE [dbo].[BeaconEvents]  WITH CHECK ADD  CONSTRAINT [FK_BeaconEvents_Employee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[BeaconEvents] CHECK CONSTRAINT [FK_BeaconEvents_Employee]
GO
ALTER TABLE [dbo].[BeaconProximityTracking]  WITH CHECK ADD  CONSTRAINT [FK_BeaconProximityTracking_BranchDevice] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[BranchDevice] ([DeviceID])
GO
ALTER TABLE [dbo].[BeaconProximityTracking] CHECK CONSTRAINT [FK_BeaconProximityTracking_BranchDevice]
GO
ALTER TABLE [dbo].[BeaconProximityTracking]  WITH CHECK ADD  CONSTRAINT [FK_BeaconProximityTracking_Employee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[BeaconProximityTracking] CHECK CONSTRAINT [FK_BeaconProximityTracking_Employee]
GO
ALTER TABLE [dbo].[Branch]  WITH CHECK ADD  CONSTRAINT [FK__Branch__CompanyI__3A81B327] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([CompanyID])
GO
ALTER TABLE [dbo].[Branch] CHECK CONSTRAINT [FK__Branch__CompanyI__3A81B327]
GO
ALTER TABLE [dbo].[BranchDevice]  WITH CHECK ADD  CONSTRAINT [FK__BranchDev__Locat__4222D4EF] FOREIGN KEY([LocationID])
REFERENCES [dbo].[BranchLocation] ([LocationID])
GO
ALTER TABLE [dbo].[BranchDevice] CHECK CONSTRAINT [FK__BranchDev__Locat__4222D4EF]
GO
ALTER TABLE [dbo].[BranchDevice]  WITH CHECK ADD  CONSTRAINT [FK_BranchDevice_DeviceType] FOREIGN KEY([DeviceTypeID])
REFERENCES [dbo].[DeviceType] ([DeviceTypeID])
GO
ALTER TABLE [dbo].[BranchDevice] CHECK CONSTRAINT [FK_BranchDevice_DeviceType]
GO
ALTER TABLE [dbo].[BranchLocation]  WITH CHECK ADD  CONSTRAINT [FK_BranchLocation_Branch] FOREIGN KEY([BranchID])
REFERENCES [dbo].[Branch] ([BranchID])
GO
ALTER TABLE [dbo].[BranchLocation] CHECK CONSTRAINT [FK_BranchLocation_Branch]
GO
ALTER TABLE [dbo].[Department]  WITH CHECK ADD  CONSTRAINT [FK__Departmen__Branc__46E78A0C] FOREIGN KEY([BranchID])
REFERENCES [dbo].[Branch] ([BranchID])
GO
ALTER TABLE [dbo].[Department] CHECK CONSTRAINT [FK__Departmen__Branc__46E78A0C]
GO
ALTER TABLE [dbo].[Employee]  WITH CHECK ADD  CONSTRAINT [FK__Employee__Branch__4CA06362] FOREIGN KEY([BranchID])
REFERENCES [dbo].[Branch] ([BranchID])
GO
ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK__Employee__Branch__4CA06362]
GO
ALTER TABLE [dbo].[Employee]  WITH CHECK ADD  CONSTRAINT [FK__Employee__Compan__4BAC3F29] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([CompanyID])
GO
ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK__Employee__Compan__4BAC3F29]
GO
ALTER TABLE [dbo].[Employee]  WITH CHECK ADD  CONSTRAINT [FK__Employee__Depart__4D94879B] FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Department] ([DepartmentID])
GO
ALTER TABLE [dbo].[Employee] CHECK CONSTRAINT [FK__Employee__Depart__4D94879B]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration]  WITH CHECK ADD  CONSTRAINT [FK_EmployeeBeaconRegistration_BranchDevice] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[BranchDevice] ([DeviceID])
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] CHECK CONSTRAINT [FK_EmployeeBeaconRegistration_BranchDevice]
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration]  WITH CHECK ADD  CONSTRAINT [FK_EmployeeBeaconRegistration_Employee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[EmployeeBeaconRegistration] CHECK CONSTRAINT [FK_EmployeeBeaconRegistration_Employee]
GO
ALTER TABLE [dbo].[EmployeeBioMetric]  WITH CHECK ADD  CONSTRAINT [FK__EmployeeB__Emplo__52593CB8] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[EmployeeBioMetric] CHECK CONSTRAINT [FK__EmployeeB__Emplo__52593CB8]
GO
ALTER TABLE [dbo].[EmployeeBioMetric]  WITH CHECK ADD  CONSTRAINT [FK_EmployeeBioMetric_BioMetricType] FOREIGN KEY([BioMetricTypeId])
REFERENCES [dbo].[BioMetricType] ([Id])
GO
ALTER TABLE [dbo].[EmployeeBioMetric] CHECK CONSTRAINT [FK_EmployeeBioMetric_BioMetricType]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut]  WITH CHECK ADD  CONSTRAINT [FK__EmployeeC__Devic__571DF1D5] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[BranchDevice] ([DeviceID])
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] CHECK CONSTRAINT [FK__EmployeeC__Devic__571DF1D5]
GO
ALTER TABLE [dbo].[EmployeeCheckInOut]  WITH CHECK ADD  CONSTRAINT [FK__EmployeeC__Emplo__5629CD9C] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[EmployeeCheckInOut] CHECK CONSTRAINT [FK__EmployeeC__Emplo__5629CD9C]
GO
ALTER TABLE [dbo].[RoleMember]  WITH CHECK ADD  CONSTRAINT [FK_RoleMember_Role] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Role] ([RoleId])
GO
ALTER TABLE [dbo].[RoleMember] CHECK CONSTRAINT [FK_RoleMember_Role]
GO
ALTER TABLE [dbo].[RoleMember]  WITH CHECK ADD  CONSTRAINT [FK_RoleMember_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[User] ([UserId])
GO
ALTER TABLE [dbo].[RoleMember] CHECK CONSTRAINT [FK_RoleMember_User]
GO
ALTER TABLE [dbo].[WorkSchedule]  WITH CHECK ADD  CONSTRAINT [FK_WorkSchedule_Branch] FOREIGN KEY([BranchID])
REFERENCES [dbo].[Branch] ([BranchID])
GO
ALTER TABLE [dbo].[WorkSchedule] CHECK CONSTRAINT [FK_WorkSchedule_Branch]
GO
ALTER TABLE [dbo].[WorkSchedule]  WITH CHECK ADD  CONSTRAINT [FK_WorkSchedule_Department] FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Department] ([DepartmentID])
GO
ALTER TABLE [dbo].[WorkSchedule] CHECK CONSTRAINT [FK_WorkSchedule_Department]
GO
ALTER TABLE [dbo].[WorkSchedule]  WITH CHECK ADD  CONSTRAINT [FK_WorkSchedule_Employee] FOREIGN KEY([EmployeeID])
REFERENCES [dbo].[Employee] ([EmployeeID])
GO
ALTER TABLE [dbo].[WorkSchedule] CHECK CONSTRAINT [FK_WorkSchedule_Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_CleanupOldBeaconEvents]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- CLEANUP AND MAINTENANCE PROCEDURES
-- =============================================

-- Clean up old beacon events (run monthly)
CREATE   PROCEDURE [dbo].[sp_CleanupOldBeaconEvents]
    @DaysToKeep INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CutoffDate DATETIME = DATEADD(DAY, -@DaysToKeep, GETDATE())
    
    -- Delete old processed events
    DELETE FROM BeaconEvents 
    WHERE IsProcessed = 1 
      AND EventTime < @CutoffDate
    
    PRINT 'Cleaned up ' + CAST(@@ROWCOUNT AS VARCHAR) + ' old beacon events.'
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePunchIn]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 1. Employee Punch In
CREATE PROCEDURE [dbo].[sp_EmployeePunchIn]
    @EmployeeID INT,
    @DeviceID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM EmployeeCheckInOut
        WHERE EmployeeID = @EmployeeID
          AND WorkDate = CAST(GETDATE() AS DATE)
    )
    BEGIN
        INSERT INTO EmployeeCheckInOut (EmployeeID, DeviceID, CheckInTime, WorkDate, Status)
        VALUES (@EmployeeID, @DeviceID, GETDATE(), CAST(GETDATE() AS DATE), 'Present');
    END
    ELSE
    BEGIN
        PRINT 'Employee already checked in today.';
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePunchInWithBeacon]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- 11. ENHANCED STORED PROCEDURES FOR iBEACON SYSTEM
-- =============================================

-- Enhanced Employee Punch In with iBeacon support
CREATE   PROCEDURE [dbo].[sp_EmployeePunchInWithBeacon]
    @EmployeeID INT,
    @DeviceID INT,
    @SignalStrength INT,
    @IsAutoPunchIn BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @WorkDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @CurrentTime DATETIME = GETDATE();
    
    -- Check if already punched in today
    IF EXISTS (
        SELECT 1 FROM EmployeeCheckInOut
        WHERE EmployeeID = @EmployeeID
          AND WorkDate = @WorkDate
          AND CheckOutTime IS NULL
    )
    BEGIN
        PRINT 'Employee already checked in today.';
        RETURN;
    END
    
    -- Get employee's work schedule
    DECLARE @ExpectedStartTime TIME;
    DECLARE @IsLate BIT = 0;
    
    SELECT TOP 1 @ExpectedStartTime = StartTime
    FROM WorkSchedule ws
    WHERE (ws.EmployeeID = @EmployeeID OR ws.EmployeeID IS NULL)
      AND (ws.DepartmentID = (SELECT DepartmentID FROM Employee WHERE EmployeeID = @EmployeeID) OR ws.DepartmentID IS NULL)
      AND (ws.BranchID = (SELECT BranchID FROM Employee WHERE EmployeeID = @EmployeeID) OR ws.BranchID IS NULL)
      AND ws.IsActive = 1
    ORDER BY 
        CASE WHEN ws.EmployeeID IS NOT NULL THEN 1 ELSE 2 END,
        CASE WHEN ws.DepartmentID IS NOT NULL THEN 1 ELSE 2 END;
    
    -- Check if late
    IF @ExpectedStartTime IS NOT NULL AND CAST(@CurrentTime AS TIME) > @ExpectedStartTime
        SET @IsLate = 1;
    
    -- Insert attendance record
    INSERT INTO EmployeeCheckInOut (
        EmployeeID, DeviceID, CheckInTime, WorkDate, Status, 
        AutoPunchIn, LastBeaconSeen, IsLate, AttendanceStatus
    )
    VALUES (
        @EmployeeID, @DeviceID, @CurrentTime, @WorkDate, 'Present',
        @IsAutoPunchIn, @CurrentTime, @IsLate, 
        CASE WHEN @IsLate = 1 THEN 'late' ELSE 'present' END
    );
    
    -- Log beacon event
    INSERT INTO BeaconEvents (EmployeeID, DeviceID, EventType, SignalStrength, EventTime)
    VALUES (@EmployeeID, @DeviceID, 'enter', @SignalStrength, @CurrentTime);
    
    -- Update employee beacon registration
    UPDATE EmployeeBeaconRegistration 
    SET LastSeen = @CurrentTime, TotalVisits = TotalVisits + 1
    WHERE EmployeeID = @EmployeeID AND DeviceID = @DeviceID;
    
    -- Log audit
    INSERT INTO AttendanceAuditLog (EmployeeID, Action, ActionBy, ActionTime)
    VALUES (@EmployeeID, 'punch_in', 'SYSTEM', @CurrentTime);
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePunchOut]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2. Employee Punch Out
CREATE PROCEDURE [dbo].[sp_EmployeePunchOut]
    @EmployeeID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE EmployeeCheckInOut
    SET CheckOutTime = GETDATE()
    WHERE EmployeeID = @EmployeeID
      AND WorkDate = CAST(GETDATE() AS DATE)
      AND CheckOutTime IS NULL;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePunchOutWithBeacon]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Enhanced Employee Punch Out with iBeacon support
CREATE   PROCEDURE [dbo].[sp_EmployeePunchOutWithBeacon]
    @EmployeeID INT,
    @DeviceID INT,
    @SignalStrength INT,
    @IsAutoPunchOut BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @WorkDate DATE = CAST(GETDATE() AS DATE);
    DECLARE @CurrentTime DATETIME = GETDATE();
    
    -- Update attendance record
    UPDATE EmployeeCheckInOut
    SET CheckOutTime = @CurrentTime,
        AutoPunchOut = @IsAutoPunchOut,
        LastBeaconSeen = @CurrentTime,
        WorkHours = DATEDIFF(MINUTE, CheckInTime, @CurrentTime) / 60.0
    WHERE EmployeeID = @EmployeeID
      AND WorkDate = @WorkDate
      AND CheckOutTime IS NULL;
    
    -- Log beacon event
    INSERT INTO BeaconEvents (EmployeeID, DeviceID, EventType, SignalStrength, EventTime)
    VALUES (@EmployeeID, @DeviceID, 'exit', @SignalStrength, @CurrentTime);
    
    -- Log audit
    INSERT INTO AttendanceAuditLog (EmployeeID, Action, ActionBy, ActionTime)
    VALUES (@EmployeeID, 'punch_out', 'SYSTEM', @CurrentTime);
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetBeaconStatus]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Get Real-time Beacon Status
CREATE   PROCEDURE [dbo].[sp_GetBeaconStatus]
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        bd.DeviceID,
        bd.NameEn AS DeviceName,
        bd.BeaconUUID,
        bd.SignalStrength,
        bd.DetectionRange,
        bd.LastSeen,
        bd.BatteryLevel,
        bd.IsBeaconEnabled,
        bl.NameEn AS LocationName,
        COUNT(ebr.EmployeeID) AS RegisteredEmployees,
        COUNT(CASE WHEN ebr.LastSeen > DATEADD(MINUTE, -5, GETDATE()) THEN 1 END) AS ActiveEmployees
    FROM BranchDevice bd
    LEFT JOIN BranchLocation bl ON bd.LocationID = bl.LocationID
    LEFT JOIN EmployeeBeaconRegistration ebr ON bd.DeviceID = ebr.DeviceID AND ebr.IsActive = 1
    WHERE (@BranchID IS NULL OR bl.BranchID = @BranchID)
      AND bd.IsActive = 1
    GROUP BY bd.DeviceID, bd.NameEn, bd.BeaconUUID, bd.SignalStrength, 
             bd.DetectionRange, bd.LastSeen, bd.BatteryLevel, bd.IsBeaconEnabled, bl.NameEn
    ORDER BY bd.LastSeen DESC;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetDailyAttendance]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Get Daily Attendance Report
CREATE PROCEDURE [dbo].[sp_GetDailyAttendance]
    @ReportDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.EmployeeID,
        e.EmployeeCode,
        e.FirstNameAr + ' ' + e.LastNameAr AS EmployeeNameAr,
		e.FirstNameEn + ' ' + e.LastNameEn AS EmployeeNameEn,
        d.NameAr,
		d.NameEn,
        b.NameAr,
		b.NameEn,
        a.CheckInTime,
        a.CheckOutTime,
        a.Status
    FROM EmployeeCheckInOut a
    INNER JOIN Employee e ON a.EmployeeID = e.EmployeeID
    INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Branch b ON e.BranchID = b.BranchID
    WHERE a.WorkDate = @ReportDate
    ORDER BY a.CheckInTime;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_GetEmployeeAttendanceHistory]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Get Employee Attendance History
CREATE PROCEDURE [dbo].[sp_GetEmployeeAttendanceHistory]
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.WorkDate,
        a.CheckInTime,
        a.CheckOutTime,
        a.Status,
        b.NameAr,
		b.NameEn,
        d.NameAr,
		d.NameEn
    FROM EmployeeCheckInOut a
    INNER JOIN Employee e ON a.EmployeeID = e.EmployeeID
    INNER JOIN Branch b ON e.BranchID = b.BranchID
    INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
    WHERE a.EmployeeID = @EmployeeID
      AND a.WorkDate BETWEEN @StartDate AND @EndDate
    ORDER BY a.WorkDate DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_GetEmployeeAttendanceWithBeacon]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- MISSING STORED PROCEDURES
-- =============================================

-- Get Employee Attendance with Beacon Data
CREATE   PROCEDURE [dbo].[sp_GetEmployeeAttendanceWithBeacon]
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        eco.AttendanceID,
        eco.WorkDate,
        eco.CheckInTime,
        eco.CheckOutTime,
        eco.AutoPunchIn,
        eco.AutoPunchOut,
        eco.LastBeaconSeen,
        eco.TotalBeaconEvents,
        eco.WorkHours,
        eco.OvertimeHours,
        eco.IsLate,
        eco.IsEarlyDeparture,
        eco.AttendanceStatus,
        eco.Notes,
        bd.NameEn AS DeviceName,
        bd.BeaconUUID,
        bl.NameEn AS LocationName,
        b.NameEn AS BranchName,
        d.NameEn AS DepartmentName
    FROM EmployeeCheckInOut eco
    INNER JOIN BranchDevice bd ON eco.DeviceID = bd.DeviceID
    INNER JOIN BranchLocation bl ON bd.LocationID = bl.LocationID
    INNER JOIN Branch b ON bl.BranchID = b.BranchID
    INNER JOIN Employee e ON eco.EmployeeID = e.EmployeeID
    INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
    WHERE eco.EmployeeID = @EmployeeID
      AND eco.WorkDate BETWEEN @StartDate AND @EndDate
    ORDER BY eco.WorkDate DESC, eco.CheckInTime DESC;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetEmployeeBeaconEvents]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Get Beacon Events for Employee
CREATE   PROCEDURE [dbo].[sp_GetEmployeeBeaconEvents]
    @EmployeeID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        be.EventID,
        be.EventType,
        be.SignalStrength,
        be.Distance,
        be.EventTime,
        be.IsProcessed,
        bd.NameEn AS DeviceName,
        bd.BeaconUUID,
        bl.NameEn AS LocationName
    FROM BeaconEvents be
    INNER JOIN BranchDevice bd ON be.DeviceID = bd.DeviceID
    INNER JOIN BranchLocation bl ON bd.LocationID = bl.LocationID
    WHERE be.EmployeeID = @EmployeeID
      AND CAST(be.EventTime AS DATE) BETWEEN @StartDate AND @EndDate
    ORDER BY be.EventTime DESC;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetLateEmployees]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Get Late Employees Report
CREATE   PROCEDURE [dbo].[sp_GetLateEmployees]
    @ReportDate DATE,
    @OfficeStartTime TIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.EmployeeID,
        e.EmployeeCode,
        e.FirstNameEn + ' ' + e.LastNameEn AS EmployeeName,
        d.NameEn AS DepartmentName,
        b.NameEn AS BranchName,
        a.CheckInTime,
        a.AttendanceStatus
    FROM EmployeeCheckInOut a
    INNER JOIN Employee e ON a.EmployeeID = e.EmployeeID
    INNER JOIN Department d ON e.DepartmentID = d.DepartmentID
    INNER JOIN Branch b ON e.BranchID = b.BranchID
    WHERE a.WorkDate = @ReportDate
      AND CAST(a.CheckInTime AS TIME) > @OfficeStartTime
      AND a.IsLate = 1
    ORDER BY a.CheckInTime;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_ProcessBeaconEvents]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Process Beacon Events (to be called periodically)
CREATE   PROCEDURE [dbo].[sp_ProcessBeaconEvents]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Process enter events for auto punch-in
    UPDATE eco
    SET AutoPunchIn = 1,
        LastBeaconSeen = be.EventTime,
        TotalBeaconEvents = TotalBeaconEvents + 1
    FROM EmployeeCheckInOut eco
    INNER JOIN BeaconEvents be ON eco.EmployeeID = be.EmployeeID
    WHERE be.EventType = 'enter'
      AND be.IsProcessed = 0
      AND eco.WorkDate = CAST(be.EventTime AS DATE)
      AND eco.CheckInTime IS NULL;
    
    -- Process exit events for auto punch-out
    UPDATE eco
    SET AutoPunchOut = 1,
        CheckOutTime = be.EventTime,
        LastBeaconSeen = be.EventTime,
        TotalBeaconEvents = TotalBeaconEvents + 1
    FROM EmployeeCheckInOut eco
    INNER JOIN BeaconEvents be ON eco.EmployeeID = be.EmployeeID
    WHERE be.EventType = 'exit'
      AND be.IsProcessed = 0
      AND eco.WorkDate = CAST(be.EventTime AS DATE)
      AND eco.CheckOutTime IS NULL;
    
    -- Mark events as processed
    UPDATE BeaconEvents
    SET IsProcessed = 1, ProcessedTime = GETDATE()
    WHERE IsProcessed = 0;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_RegisterEmployeeWithBeacon]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Register Employee with Beacon
CREATE   PROCEDURE [dbo].[sp_RegisterEmployeeWithBeacon]
    @EmployeeID INT,
    @DeviceID INT,
    @CreatedBy NVARCHAR(100) = 'SYSTEM'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if already registered
    IF EXISTS (SELECT 1 FROM EmployeeBeaconRegistration 
               WHERE EmployeeID = @EmployeeID AND DeviceID = @DeviceID AND IsActive = 1)
    BEGIN
        PRINT 'Employee already registered with this beacon.';
        RETURN;
    END
    
    -- Insert registration
    INSERT INTO EmployeeBeaconRegistration (EmployeeID, DeviceID, CreatedBy)
    VALUES (@EmployeeID, @DeviceID, @CreatedBy);
    
    PRINT 'Employee successfully registered with beacon.';
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_UpdateBeaconProximityTracking]    Script Date: 9/23/2025 12:15:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Update beacon proximity tracking
CREATE   PROCEDURE [dbo].[sp_UpdateBeaconProximityTracking]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Update duration for completed sessions
    UPDATE bpt
    SET DurationMinutes = DATEDIFF(MINUTE, bpt.EnterTime, bpt.ExitTime),
        AverageSignalStrength = (
            SELECT AVG(CAST(SignalStrength AS DECIMAL(5,2)))
            FROM BeaconEvents be
            WHERE be.EmployeeID = bpt.EmployeeID
              AND be.DeviceID = bpt.DeviceID
              AND be.EventTime BETWEEN bpt.EnterTime AND ISNULL(bpt.ExitTime, GETDATE())
        )
    FROM BeaconProximityTracking bpt
    WHERE bpt.ExitTime IS NOT NULL
      AND bpt.DurationMinutes IS NULL;
END;

GO
