SELECT Name 
FROM Dish
WHERE Price < 15;


SELECT o.OrderId, o.TotalAmount, o.OrderDate
FROM Orders o
WHERE EXTRACT(YEAR FROM o.OrderDate) = 2023
  AND o.TotalAmount > 50;


SELECT w.Name, w.Surname, COUNT(o.OrderId) AS NumberOfDeliveries
FROM Workers w
JOIN Orders o ON o.DeliveryPersonId = w.WorkersId
WHERE w.Role = 'Dostavljac'
GROUP BY w.WorkersId
HAVING COUNT(o.OrderId) > 100;


SELECT w.Name, w.Surname
FROM Workers w
JOIN Restaurant r ON w.RestaurantId = r.RestaurantId
JOIN Cities c ON r.CityId = c.CityId
WHERE w.Role = 'Kuhar'
  AND c.Name = 'Zagreb';


SELECT r.Name AS RestaurantName, COUNT(o.OrderId) AS NumberOfOrders
FROM Orders o
JOIN Restaurant r ON o.RestaurantId = r.RestaurantId
JOIN Cities c ON r.CityId = c.CityId
WHERE c.Name = 'Split'
  AND EXTRACT(YEAR FROM o.OrderDate) = 2023
GROUP BY r.RestaurantId;


SELECT d.Name, COUNT(od.OrderDetailsId) AS OrderCount
FROM OrderDetails od
JOIN Dish d ON od.DishId = d.DishId
JOIN Orders o ON od.OrderId = o.OrderId
WHERE d.Category = 'Desert'
  AND EXTRACT(MONTH FROM o.OrderDate) = 12
  AND EXTRACT(YEAR FROM o.OrderDate) = 2023
GROUP BY d.DishId
HAVING COUNT(od.OrderDetailsId) > 10;


SELECT u.Name, u.Surname, COUNT(o.OrderId) AS NumberOfOrders
FROM Users u
JOIN Orders o ON u.UserId = o.UserId
WHERE u.Surname LIKE 'M%'
GROUP BY u.UserId;



SELECT r.Name AS RestaurantName, AVG(rt.Rating) AS AverageRating
FROM Ratings rt
JOIN Dish d ON rt.RatedDishId = d.DishId
JOIN Restaurant r ON d.MenuId = r.RestaurantId
JOIN Cities c ON r.CityId = c.CityId
WHERE c.Name = 'Rijeka'
GROUP BY r.RestaurantId;



SELECT r.Name
FROM Restaurant r
WHERE r.Capacity > 30
  AND EXISTS (
      SELECT 1
      FROM Orders o
      WHERE o.RestaurantId = r.RestaurantId
      AND o.OrderType = 'Dostava'
  );



DELETE FROM Dish
WHERE DishId NOT IN (
    SELECT DISTINCT od.DishId
    FROM OrderDetails od
    JOIN Orders o ON od.OrderId = o.OrderId
    WHERE o.OrderDate >= CURRENT_DATE - INTERVAL '2 years'
);


UPDATE Users u
SET LoyaltyCard = FALSE
WHERE u.UserId NOT IN (
    SELECT DISTINCT o.UserId
    FROM Orders o
    JOIN OrderDetails od ON o.OrderId = od.OrderId
    WHERE o.OrderDate >= CURRENT_DATE - INTERVAL '1 year'
);


