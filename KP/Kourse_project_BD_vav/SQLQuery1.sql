-- Microsoft SQL Server

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(100) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    email NVARCHAR(255) NOT NULL UNIQUE,
    full_name NVARCHAR(255) NOT NULL,
    role NVARCHAR(50) CHECK (role IN ('admin', 'realtor', 'client')),
    created_at DATETIME DEFAULT GETDATE(),
    client_id INT NULL,
    realtor_id INT NULL
);

CREATE TABLE Clients (
    client_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    phone_number NVARCHAR(50),
    email NVARCHAR(255),
    passport_number NVARCHAR(100),
    registration_date DATETIME DEFAULT GETDATE(),
    user_id INT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Realtors (
    realtor_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(255) NOT NULL,
    phone_number NVARCHAR(50),
    email NVARCHAR(255),
    hire_date DATE,
    commission_rate DECIMAL(5,2),
    user_id INT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Связь Users -> Clients, Realtors (после создания таблиц)
ALTER TABLE Users ADD CONSTRAINT FK_Users_Clients FOREIGN KEY (client_id) REFERENCES Clients(client_id);
ALTER TABLE Users ADD CONSTRAINT FK_Users_Realtors FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id);

CREATE TABLE Properties (
    property_id INT IDENTITY(1,1) PRIMARY KEY,
    address NVARCHAR(500) NOT NULL,
    property_type NVARCHAR(100),
    area DECIMAL(10,2),
    price DECIMAL(18,2),
    description NVARCHAR(MAX),
    realtor_id INT,
    is_available BIT DEFAULT 1,
    main_image_url NVARCHAR(500),
    image_urls NVARCHAR(MAX), -- можно хранить JSON
    rooms INT,
    floor INT,
    total_floor INT,
    FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
);

CREATE TABLE Favorites (
    favorite_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    property_id INT NOT NULL,
    added_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    CONSTRAINT UQ_Favorites_UserProperty UNIQUE (user_id, property_id)
);

CREATE TABLE Deals (
    deal_id INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    realtor_id INT NOT NULL,
    deal_type NVARCHAR(50),
    deal_date DATE,
    deal_price DECIMAL(18,2),
    FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    FOREIGN KEY (client_id) REFERENCES Clients(client_id),
    FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
);

CREATE TABLE Contracts (
    contact_id INT IDENTITY(1,1) PRIMARY KEY,
    deal_id INT NOT NULL,
    contract_date DATE,
    contract_file NVARCHAR(500),
    notes NVARCHAR(MAX),
    FOREIGN KEY (deal_id) REFERENCES Deals(deal_id)
);

CREATE TABLE PropertyReservations (
    UniquedID INT IDENTITY(1,1) PRIMARY KEY,
    reservation_id INT NOT NULL,
    property_id INT NOT NULL,
    client_id INT NOT NULL,
    realtor_id INT NOT NULL,
    FOREIGN KEY (property_id) REFERENCES Properties(property_id),
    FOREIGN KEY (client_id) REFERENCES Clients(client_id),
    FOREIGN KEY (realtor_id) REFERENCES Realtors(realtor_id)
);
