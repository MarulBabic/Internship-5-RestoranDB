CREATE TABLE Cities (
	CityId SERIAL PRIMARY KEY,
	Name VARCHAR(30) NOT NULL UNIQUE
)

CREATE TABLE Restaurant(
	RestaurantId SERIAL PRIMARY KEY,
	Name VARCHAR(50) NOT NULL,
	CityId INT REFERENCES Cities(CityID),
	Capacity INT CHECK (Capacity > 0) NOT NULL,
	OpeningTime TIME NOT NULL,
	ClosingTime TIME NOT NULL
)

ALTER TABLE Restaurant
	ADD CONSTRAINT CheckWorkingHours CHECK (OpeningTime < ClosingTime);

CREATE TABLE Menu(
	MenuId SERIAL PRIMARY KEY,
	RestaurantId INT REFERENCES Restaurant(RestaurantId)
)

CREATE TABLE Dish(
	DishId SERIAL PRIMARY KEY,
	Name VARCHAR(30) NOT NULL,
	Category VARCHAR(30) NOT NULL,
	Price DECIMAL(10, 2) CHECK (Price >= 0) NOT NULL,
	Calories INT NOT NULL,
    IsAvailable BOOLEAN NOT NULL,
	MenuId INT REFERENCES Menu(MenuId)
)

ALTER TABLE Dish
	ADD CONSTRAINT CheckDishCategory CHECK (Category IN ('Predjelo', 'Glavno jelo', 'Desert'))

CREATE TABLE Users(
	UserId SERIAL PRIMARY KEY,
	Name VARCHAR(20) NOT NULL,
	Surname VARCHAR(20) NOT NULL,
	LoyaltyCard BOOLEAN NOT NULL,
	TotalSpend DECIMAL(10, 2) CHECK (TotalSpend >= 0) NOT NULL
)

CREATE TABLE Workers(
	WorkersId SERIAL PRIMARY KEY,
	Name VARCHAR(50) NOT NULL,
	Surname VARCHAR(50) NOT NULL,
	Role VARCHAR(30) NOT NULL,
	Age INT CHECK (Age >= 18) NOT NULL,
    DriverLicense BOOLEAN DEFAULT FALSE,
	RestaurantId INT REFERENCES Restaurant(RestaurantId)
)

ALTER TABLE Workers
	ADD CONSTRAINT CheckWorkerRole CHECK(Role IN ('Konobar','Dostavljac','Kuhar'))
	
ALTER TABLE Workers
	ADD CONSTRAINT CheckChefAge CHECK(Role != 'Kuhar' OR Age >= 18)
	
ALTER TABLE Workers
	ADD CONSTRAINT CheckDriversLicense CHECK(Role != 'Dostavljac' OR DriverLicense = TRUE)
	

CREATE TABLE Orders(
	OrderId SERIAL PRIMARY KEY,
	UserId INT REFERENCES Users(UserId),
	RestaurantId INT REFERENCES Restaurant(RestaurantId),
	OrderType VARCHAR(20) NOT NULL,
	DeliveryAddress VARCHAR(255),
	DeliveryTime TIMESTAMP,
	DeliveryPersonId INT REFERENCES Workers(WorkersId),
	Notes TEXT,
	TotalAmount DECIMAL(10, 2) NOT NULL 
)

ALTER TABLE Orders
	ADD CONSTRAINT CheckOrderType CHECK (OrderType IN ('Dostava','Konzumacija u restoranu'))
	
ALTER TABLE Orders
ADD COLUMN OrderDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE Orders
	ALTER COLUMN OrderType TYPE VARCHAR(50)

CREATE TABLE OrderDetails (
    OrderDetailsId SERIAL PRIMARY KEY,
    OrderId INT REFERENCES Orders(OrderId),      
    DishId INT REFERENCES Dish(DishId),          
    Quantity INT NOT NULL,                        
    TotalPrice DECIMAL(10, 2) NOT NULL           
)

CREATE TABLE Ratings (
		RatingId SERIAL PRIMARY KEY,
		UserId INT REFERENCES Users(UserId),   
		Rating INT CHECK (Rating BETWEEN 1 AND 5), 
		Comment TEXT,                          
		RatingDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,  
		RatedDishId INT REFERENCES Dish(DishId),  
		RatedDeliveryPersonId INT REFERENCES Workers(WorkersId)             
)

CREATE OR REPLACE FUNCTION UpdateLoyaltyCard()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        (SELECT COUNT(*) FROM Orders WHERE UserId = NEW.UserId) > 15
        AND 
        (SELECT COALESCE(SUM(TotalAmount), 0) FROM Orders WHERE UserId = NEW.UserId) > 1000
    ) THEN
        UPDATE Users
        SET LoyaltyCard = TRUE
        WHERE UserId = NEW.UserId;
    ELSE
        UPDATE Users
        SET LoyaltyCard = FALSE
        WHERE UserId = NEW.UserId;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER CheckLoyaltyCard
AFTER INSERT OR UPDATE ON Orders
FOR EACH ROW
EXECUTE FUNCTION UpdateLoyaltyCard();


CREATE OR REPLACE FUNCTION UpdateTotalAmount()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Orders
    SET TotalAmount = (
        SELECT COALESCE(SUM(TotalPrice), 0)
        FROM OrderDetails
        WHERE OrderDetails.OrderId = NEW.OrderId
    )
    WHERE Orders.OrderId = NEW.OrderId;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UpdateOrderTotal
AFTER INSERT OR UPDATE OR DELETE ON OrderDetails
FOR EACH ROW
EXECUTE FUNCTION UpdateTotalAmount();