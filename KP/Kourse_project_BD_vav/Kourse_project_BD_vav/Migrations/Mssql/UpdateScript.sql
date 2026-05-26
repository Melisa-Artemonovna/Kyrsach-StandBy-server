IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
GO

CREATE TABLE [Clients] (
    [client_id] int NOT NULL IDENTITY,
    [full_name] nvarchar(100) NOT NULL,
    [phone_number] nvarchar(20) NOT NULL,
    [email] nvarchar(100) NOT NULL,
    [passport_number] nvarchar(20) NOT NULL,
    [registration_date] datetime2 NOT NULL DEFAULT (GETDATE()),
    [user_id] int NULL,
    CONSTRAINT [PK_Clients] PRIMARY KEY ([client_id])
);
GO

CREATE TABLE [Contracts] (
    [contract_id] int NOT NULL IDENTITY,
    [deal_id] int NOT NULL,
    [contract_date] datetime2 NOT NULL,
    [contract_file] nvarchar(255) NOT NULL,
    [notes] text NOT NULL,
    CONSTRAINT [PK_Contracts] PRIMARY KEY ([contract_id])
);
GO

CREATE TABLE [Favorites] (
    [favorite_id] int NOT NULL IDENTITY,
    [user_id] int NOT NULL,
    [property_id] int NOT NULL,
    [added_at] datetime2 NOT NULL DEFAULT (GETDATE()),
    [added_date] datetime2 NOT NULL,
    CONSTRAINT [PK_Favorites] PRIMARY KEY ([favorite_id])
);
GO

CREATE TABLE [Properties] (
    [property_id] int NOT NULL IDENTITY,
    [address] nvarchar(255) NOT NULL,
    [property_type] nvarchar(50) NOT NULL,
    [area] decimal(10,2) NOT NULL,
    [price] decimal(15,2) NOT NULL,
    [description] text NOT NULL,
    [realtor_id] int NULL,
    [is_available] bit NOT NULL,
    [main_image_url] nvarchar(500) NULL,
    [image_urls] text NULL,
    [rooms] int NULL,
    [floor] int NULL,
    [total_floors] int NULL,
    CONSTRAINT [PK_Properties] PRIMARY KEY ([property_id])
);
GO

CREATE TABLE [PropertyReservations] (
    [reservation_id] int NOT NULL IDENTITY,
    [property_id] int NOT NULL,
    [client_id] int NOT NULL,
    [realtor_id] int NULL,
    [reservation_date] datetime2 NOT NULL DEFAULT (GETDATE()),
    [expiry_date] datetime2 NOT NULL,
    [status] nvarchar(20) NOT NULL DEFAULT N'Active',
    [notes] nvarchar(max) NULL,
    CONSTRAINT [PK_PropertyReservations] PRIMARY KEY ([reservation_id])
);
GO

CREATE TABLE [UserActivities] (
    [activity_id] int NOT NULL IDENTITY,
    [user_id] int NOT NULL,
    [activity_type] nvarchar(50) NOT NULL,
    [description] nvarchar(255) NULL,
    [created_at] datetime2 NOT NULL DEFAULT (GETDATE()),
    CONSTRAINT [PK_UserActivities] PRIMARY KEY ([activity_id])
);
GO

CREATE TABLE [Users] (
    [user_id] int NOT NULL IDENTITY,
    [username] nvarchar(50) NOT NULL,
    [password_hash] nvarchar(255) NOT NULL,
    [email] nvarchar(100) NOT NULL,
    [full_name] nvarchar(100) NOT NULL,
    [role] nvarchar(20) NOT NULL,
    [created_at] datetime2 NOT NULL DEFAULT (GETDATE()),
    [client_id] int NULL,
    [realtor_id] int NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([user_id])
);
GO

CREATE TABLE [Realtors] (
    [realtor_id] int NOT NULL IDENTITY,
    [full_name] nvarchar(100) NOT NULL,
    [phone_number] nvarchar(20) NOT NULL,
    [email] nvarchar(100) NOT NULL,
    [hire_date] datetime2 NOT NULL DEFAULT (GETDATE()),
    [commission_rate] decimal(5,2) NOT NULL,
    [user_id] int NULL,
    CONSTRAINT [PK_Realtors] PRIMARY KEY ([realtor_id]),
    CONSTRAINT [FK_Realtors_Users_user_id] FOREIGN KEY ([user_id]) REFERENCES [Users] ([user_id])
);
GO

CREATE TABLE [Deals] (
    [deal_id] int NOT NULL IDENTITY,
    [property_id] int NOT NULL,
    [client_id] int NOT NULL,
    [realtor_id] int NULL,
    [deal_type] nvarchar(50) NOT NULL,
    [deal_status] nvarchar(50) NOT NULL,
    [deal_date] datetime2 NOT NULL,
    [deal_price] decimal(15,2) NOT NULL,
    CONSTRAINT [PK_Deals] PRIMARY KEY ([deal_id]),
    CONSTRAINT [FK_Deals_Clients_client_id] FOREIGN KEY ([client_id]) REFERENCES [Clients] ([client_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Deals_Properties_property_id] FOREIGN KEY ([property_id]) REFERENCES [Properties] ([property_id]) ON DELETE CASCADE,
    CONSTRAINT [FK_Deals_Realtors_realtor_id] FOREIGN KEY ([realtor_id]) REFERENCES [Realtors] ([realtor_id])
);
GO

CREATE INDEX [IX_Deals_client_id] ON [Deals] ([client_id]);
GO

CREATE INDEX [IX_Deals_property_id] ON [Deals] ([property_id]);
GO

CREATE INDEX [IX_Deals_realtor_id] ON [Deals] ([realtor_id]);
GO

CREATE INDEX [IX_Realtors_user_id] ON [Realtors] ([user_id]);
GO

CREATE UNIQUE INDEX [IX_Users_email] ON [Users] ([email]);
GO

CREATE UNIQUE INDEX [IX_Users_username] ON [Users] ([username]);
GO

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20251216220734_InitialCreate_Mssql', N'8.0.0');
GO

COMMIT;
GO

