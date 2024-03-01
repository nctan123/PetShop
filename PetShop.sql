﻿CREATE DATABASE PETSHOP;
USE PETSHOP;

-- Create the Accounts table
CREATE TABLE Accounts (
  Acc_id INT IDENTITY(1,1) PRIMARY KEY ,
  Email VARCHAR(50) NOT NULL,
  Password VARCHAR(50) NOT NULL,
  PhoneNumber VARCHAR(50) NOT NULL,
  FullName NVARCHAR(50) NOT NULL,
  Register_Date DATE NOT NULL,
  Role VARCHAR(50) NOT NULL,
  Status INT NOT NULL
);

-- Create the TypePets table
CREATE TABLE TypePets (
  Typepet_id VARCHAR(50) PRIMARY KEY NOT NULL,
  Name VARCHAR(50) NOT NULL
);

-- Create the Breeds table
CREATE TABLE Breeds (
  Breed_id VARCHAR(50) PRIMARY KEY NOT NULL,
  Typepet_id VARCHAR(50),
  Name VARCHAR(50) NOT NULL,
  FOREIGN KEY (Typepet_id) REFERENCES TypePets(Typepet_id)
);


-- Create the Pets table
CREATE TABLE Pets (
  Pet_id VARCHAR(50) PRIMARY KEY ,
  Acc_id INT,
  Breed_id VARCHAR(50),
  Typepet_id VARCHAR(50),
  Weight DECIMAL(4,1) NOT NULL,
  Status INT NOT NULL,
  FOREIGN KEY (Acc_id) REFERENCES Accounts(Acc_id),
  FOREIGN KEY (Breed_id) REFERENCES Breeds(Breed_id),
  FOREIGN KEY (Typepet_id) REFERENCES TypePets(Typepet_id)
);



-- Create the TypeServices table
CREATE TABLE TypeServices (
  Typeservice_id VARCHAR(50) PRIMARY KEY NOT NULL,
  Name VARCHAR(50) NOT NULL,
  Description VARCHAR(255) NOT NULL,
  Status INT NOT NULL
);

-- Create the Services table
CREATE TABLE Services(
  Service_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  Typeservice_id VARCHAR(50) REFERENCES TypeServices(Typeservice_id),
  Typepet_id VARCHAR(50) REFERENCES TypePets(Typepet_id),
  Description VARCHAR(255) NOT NULL,
  Weight_range DECIMAL(4,1) NULL,
  Price INT NOT NULL,
  Discount INT NULL,
  Quantity INT NULL,
  Image VARCHAR(50) NOT NULL,
  Status INT NOT NULL
);

-- Create the Payments table
CREATE TABLE Payments (
  Payment_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  Payment_date DATETIME,
  Type_payment INT,
  Status INT NOT NULL
);

-- Create the Feedback table
CREATE TABLE Feedback (
  Feedback_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
  Feedback_text VARCHAR(255) NOT NULL,
  Reply_text VARCHAR(255) NULL,
  Reply_date DATETIME NULL,
  Status INT NOT NULL,
  
);



-- Create the Orders table
CREATE TABLE Orders (
  Order_id INT IDENTITY(1,1) PRIMARY KEY,
  Acc_id INT,
  Total_price INT NOT NULL,
  Order_date DATETIME NOT NULL,
  Payment_id INT NOT NULL,
  Feedback_id INT NULL,
  Status INT NOT NULL,
  FOREIGN KEY (Acc_id) REFERENCES Accounts(Acc_id),
  FOREIGN KEY (Payment_id) REFERENCES Payments(Payment_id),
  FOREIGN KEY (Feedback_id) REFERENCES Feedback(Feedback_id)
);


-- Create the OrdersDetails table
CREATE TABLE OrdersDetails (
  OrderDetail_id INT IDENTITY(1,1)  PRIMARY KEY,
  Order_id INT,
  Service_id INT,
  Pet_id VARCHAR(50) NULL,
  Start_time DATETIME NULL,
  End_time DATETIME NULL,
  Quantity INT,
  Price INT,
  FOREIGN KEY (Order_id) REFERENCES Orders(Order_id),
  FOREIGN KEY (Service_id) REFERENCES Services(Service_id),
  FOREIGN KEY (Pet_id) REFERENCES Pets(Pet_id)
);

------------------------------------------Ràng Buộc-----------------------------------------

-- Email
ALTER TABLE Accounts
ADD CONSTRAINT CHK_Email CHECK (Email LIKE '%@gmail.com');

-- PhoneNumber
ALTER TABLE Accounts
ADD CONSTRAINT CHK_PhoneNumber CHECK (LEN(PhoneNumber) = 10);

-- Trigger CalculateOrderDetailsPrice
GO
CREATE TRIGGER CalculateOrderDetailsPrice
ON OrdersDetails
AFTER INSERT, UPDATE
AS
BEGIN
  UPDATE od
  SET Price = s.Price * od.Quantity * (100-s.Discount)/100
  FROM OrdersDetails od
  INNER JOIN Services s ON od.Service_id = s.Service_id
  INNER JOIN inserted i ON od.OrderDetail_id = i.OrderDetail_id;
END;
GO

-- Trigger CheckTime
GO
CREATE TRIGGER CheckTime
ON OrdersDetails
AFTER INSERT, UPDATE
AS
BEGIN
  IF EXISTS (
    SELECT 1
    FROM inserted i
    INNER JOIN Orders o ON i.Order_id = o.Order_id
    WHERE i.Start_time < o.Order_date OR i.End_time < o.Order_date
  )
  BEGIN
    RAISERROR ('Invalid time range', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END;
END;
GO

-- Trigger CheckPaymentDate
GO
CREATE TRIGGER CheckPaymentDate
ON Payments
AFTER INSERT, UPDATE
AS
BEGIN
  IF EXISTS (
    SELECT 1
    FROM inserted i
    INNER JOIN Orders o ON i.Payment_id = o.Payment_id
    WHERE i.Payment_date < o.Order_date
  )
  BEGIN
    RAISERROR ('Invalid payment date', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END;
END;
GO

-- Trigger CheckFeedbackDate
GO
CREATE TRIGGER CheckFeedbackDate
ON Feedback
AFTER INSERT, UPDATE
AS
BEGIN
  IF EXISTS (
    SELECT 1
    FROM inserted i
    INNER JOIN Orders o ON i.Feedback_id = o.Feedback_id
    WHERE i.Reply_date < o.Order_date
  )
  BEGIN
    RAISERROR ('Invalid feedback reply date', 16, 1);
    ROLLBACK TRANSACTION;
    RETURN;
  END;
END;
GO

-- Trigger CalculateTotalPrice
GO
CREATE TRIGGER CalculateTotalPrice
ON OrdersDetails
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
  UPDATE o
  SET Total_price = (
    SELECT SUM(od.Price)
    FROM OrdersDetails od
    WHERE od.Order_id = o.Order_id
  )
  FROM Orders o
  INNER JOIN inserted i ON o.Order_id = i.Order_id
  WHERE o.Order_id IN (SELECT Order_id FROM inserted);
END;
GO
---------------------------------------------INSERT DATA----------------------------------

-- Insert data into the Accounts table
INSERT INTO Accounts(Email, Password, PhoneNumber, FullName, Register_Date, Role, Status)
VALUES 
  ( 'vana@gmail.com', 'password123', '0823456789', N'Nguyễn Văn An', '2024-02-29', 'Admin', 1),
  ( 'thib@gmail.com', 'test123', '0823456780', N'Trần Thị Bé', '2024-02-29', 'User', 1),
  ( 'vanc@gmail.com', 'pass123', '0923456781', N'Lê Văn Cường', '2024-02-29', 'User', 1),
  ( 'thid@gmail.com', 'pass456', '0123456782', N'Phạm Thị Dung', '2024-02-29', 'User', 1),
  ( 'hoangvane@gmail.com', 'pass789', '0623456783', N'Hoàng Văn Em', '2024-02-29', 'User', 1),
  ( 'ngothi@gmail.com', 'qwerty123', '0523456784', N'Ngô Thị Hoa', '2024-02-29', 'User', 1),
  ( 'vandang123@gmail.com', 'qwerty456', '0123456785', N'Đặng Văn Giang', '2024-02-29', 'Admin', 1),
  ( 'buithi@gmail.com', 'qwerty789', '0323456786', N'Bùi Thị Hồng', '2024-02-29', 'User', 1),
  ( 'vuvan@gmail.com', 'passpass123', '0123456787', N'Vũ Văn Anh', '2024-02-29', 'User', 1),
  ( 'thivo500@gmail.com', 'passpass456', '0223456788', N'Võ Thị Kim', '2024-02-29', 'User', 1);




-- Insert data into the TypeServices table
INSERT INTO TypeServices (Typeservice_id, Name, Description, Status)
VALUES ('A', 'Hotel Service', 'Pet-sitting service', 1),
       ('B', 'SPA Service', 'Pet cleaning service', 1),
       ('C', 'Grooming Service', 'Pet beauty service', 1),
       ('D', 'Pet Food', 'Product of pet food', 1);

-- Insert data into the TypePets table
INSERT INTO TypePets (Typepet_id, Name)
VALUES ('TP01', 'Dog'),
       ('TP02', 'Cat'),
       ('TP03', 'Mouse');

-- Insert data into the Breeds table
INSERT INTO Breeds (Breed_id, Typepet_id, Name)
VALUES ('BR01', 'TP01', 'Labrador Retriever'),
       ('BR02', 'TP01', 'German Shepherd'),
       ('BR03', 'TP02', 'Persian'),
       ('BR04', 'TP02', 'Siamese'),
       ('BR05', 'TP03', 'White Fancy Mouse'),
       ('BR06', 'TP03', 'Dumbo Rat'),
       ('BR07', 'TP01', 'Golden Retriever'),
       ('BR08', 'TP01', 'Bulldog'),
       ('BR09', 'TP02', 'Maine Coon'),
       ('BR10', 'TP02', 'Bengal'),
       ('BR11', 'TP01', 'Poodle'),
       ('BR12', 'TP01', 'Siberian Husky');

-- Insert data into the Pets table
INSERT INTO Pets (Pet_id, Acc_id, Breed_id, Typepet_id, Weight, Status)
VALUES ('P0001', 2, 'BR01', 'TP01', 15.5, 1),
       ('P0002', 3, 'BR03', 'TP02', 8.2, 1),
       ('P0003', 4, 'BR07', 'TP01', 25.0, 1),
       ('P0004', 6, 'BR05', 'TP03', 0.8, 1),
       ('P0005', 8, 'BR10', 'TP02', 6.7, 1),
       ('P0006', 10, 'BR02', 'TP01', 12.3, 1),
       ('P0007', 3, 'BR09', 'TP02', 9.5, 1),
       ('P0008', 8, 'BR06', 'TP03', 1.2, 1),
       ('P0009', 5, 'BR08', 'TP01', 18.7, 1),
       ('P0010', 10, 'BR04', 'TP02', 7.9, 1);

-- Insert data into the Services table
INSERT INTO Services(Typeservice_id, Typepet_id, Description, Weight_range, Price, Discount, Quantity, Image, Status)
VALUES 
  ( 'A', 'TP01', '75 x 55 x 60', 10, 100,0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '75 x 55 x 60', 10, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '75 x 55 x 60', 10, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '75 x 55 x 60', 10, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '105 x 85 x 100', 20, 150, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '105 x 85 x 100', 20, 150, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '105 x 85 x 100', 20, 150, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '105 x 85 x 100', 20, 150, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '115 x 95 x 115', 40, 300, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '115 x 95 x 115', 40, 300, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '115 x 95 x 115', 40, 300, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP01', '115 x 95 x 115', 40, 300, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '55 x 45 x 60', 4, 80, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '55 x 45 x 60', 4, 80, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '55 x 45 x 60', 4, 80, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '65 x 65 x 80', 8, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '65 x 65 x 80', 8, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '65 x 65 x 80', 8, 100, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '80 x 75 x 100', 13, 160, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '80 x 75 x 100', 13, 160, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP02', '80 x 75 x 100', 13, 160, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP03', '20 x 30 x 25', 1, 60, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP03', '20 x 30 x 25', 1, 60, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP03', '20 x 30 x 25', 1, 60, 0, NULL, 'img01.jpg', 1),
  ( 'A', 'TP03', '20 x 30 x 25', 1, 60, 0, NULL, 'img01.jpg', 1),

  ( 'B', 'TP01', 'Shower gel: Bubble Bath, Hair care serum: Argan Oil', 10, 150, 10, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Spa Bath, Hair care serum: Coconut Oil', 10, 180, 5, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Herbal Bath, Hair care serum: Jojoba Oil', 10, 200, 0, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Bubble Bath, Hair care serum: Argan Oil', 20, 180, 10, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Spa Bath, Hair care serum: Coconut Oil', 20, 210, 5, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Herbal Bath, Hair care serum: Jojoba Oil', 20, 250, 0, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Bubble Bath, Hair care serum: Argan Oil', 40, 250, 10, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Spa Bath, Hair care serum: Coconut Oil', 40, 280, 5, NULL, 'img01.jpg', 1),
  ( 'B', 'TP01', 'Shower gel: Herbal Bath, Hair care serum: Jojoba Oil', 40, 310, 0, NULL, 'img01.jpg', 1),
  ( 'B', 'TP02', 'Shower gel: Bubble Bath, Hair care serum: Argan Oil', 13, 150, 10, NULL, 'img01.jpg', 1),
  ( 'B', 'TP02', 'Shower gel: Spa Bath, Hair care serum: Coconut Oil', 13, 120, 5, NULL, 'img01.jpg', 1),
  ( 'B', 'TP02', 'Shower gel: Herbal Bath, Hair care serum: Jojoba Oil', 13, 100,0, NULL, 'img01.jpg', 1),


  ( 'C', 'TP01', 'Haircut Type: Trim Only', 10, 110, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Dye', 10, 130, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Style', 10, 190, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim Only', 20, 130, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Dye', 20, 160, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Style', 20, 210, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim Only', 40, 200, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Dye', 40, 250, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP01', 'Haircut Type: Trim and Style', 40, 290, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim Only', 4, 60, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim and Dye', 4, 70, 15, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim and Style', 4, 90, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim Only', 13, 70, 0, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim and Dye', 13, 100, 15, NULL, 'img01.jpg', 1),
  ( 'C', 'TP02', 'Haircut Type: Trim and Style', 13, 120, 0, NULL, 'img01.jpg', 1),

  ( 'D', 'TP01', 'Royal Canin-5kg', 10, 100, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Royal Canin-10kg', 10, 190, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Royal Canin-15kg', 10, 280, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Purina Pro Plan-5kg', 20, 110, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Purina Pro Plan-10kg', 20, 200, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Purina Pro Plan-15kg', 20, 290, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Blue Buffalo-5kg', 10, 150, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Blue Buffalo-10kg', 10, 300, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP01', 'Blue Buffalo-15kg', 10, 340, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Royal Canin-1kg', 4, 30, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Royal Canin-1.5kg', 4, 40, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Royal Canin-2kg', 4, 50, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Sheba-1kg', 4, 35, 0 ,10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Sheba-1.5kg', 4, 45, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Sheba-2kg', 4, 55, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Nutro-1kg', 13, 40, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Nutro-1.5kg', 13, 65, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP02', 'Nutro-2kg', 13, 75, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP03', 'Beans-1.5kg', 1, 20, 0, 10, 'img01.jpg', 1),
  ( 'D', 'TP03', 'Beans-2kg', 1, 40, 0, 10, 'img01.jpg', 1);

-- Insert data into the Payments table
INSERT INTO Payments (Payment_date, Type_payment, Status)
VALUES
('2024-02-28 10:00:00', 1, 1),
('2024-02-28 14:30:00', 2, 0),
('2024-02-29 09:15:00', 1, 1);

-- Insert data into the Feedback table
INSERT INTO Feedback (Feedback_text, Reply_text, Reply_date, Status)
VALUES
('Great service! My pet loved it.', 'Thank you for your feedback!', '2024-02-28 11:00:00', 1),
('Average service. Could be better.', NULL, NULL, 0),
('Excellent grooming service!', 'We are glad you liked it!', '2024-02-29 10:30:00', 1);

-- Insert data into the Orders table
INSERT INTO Orders (Acc_id, Total_price, Order_date, Payment_id, Feedback_id, Status)
VALUES
(5, 900, '2024-02-28 12:00:00', 1, NULL, 1),
(10, 1100, '2024-02-28 16:45:00', 2, 1, 1),
(8, 135, '2024-02-29 11:30:00', 3, 3, 1);

-- Insert data into the OrdersDetails table
INSERT INTO OrdersDetails (Order_id, Service_id, Pet_id, Start_time, End_time, Quantity)
VALUES
(1, 12, 'P0009', '2024-02-28 12:00:00', '2024-03-01 12:00:00', 2),
(1, 60, NULL, NULL, NULL, 1),
(2, 19, 'P0010', '2024-02-28 16:45:00', '2024-03-03 12:00:00', 5),
(2, 5, 'P0006', '2024-02-28 16:45:00', '2024-03-03 12:00:00', 1),
(3, 64, NULL, NULL, NULL, 3),
(3, 35, 'P0005', '2024-02-29 11:30:00', '2024-02-29 12:30:00', 1)









