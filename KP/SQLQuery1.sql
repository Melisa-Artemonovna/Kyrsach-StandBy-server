INSERT INTO Clients (full_name, phone_number, email, passport_number, registration_date) 
VALUES ('Иванов Иван Иванович', '+79991234567', 'test@example.com', '1234567890', GETDATE());

SELECT * FROM Clients WHERE email = 'test@example.com';

INSERT INTO Realtors (full_name, phone_number, email,hire_date,commission_rate)
VALUES ('Первушин Артём Александрович' , '+375295071899' , 'artem.pervushin.2017@mail.ru', GETDATE(),5.5);

Select * from Realtors


SELECT name FROM sys.tables WHERE name LIKE 'AspNet%'