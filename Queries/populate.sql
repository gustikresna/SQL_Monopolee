-- NAME: I GUSTI NGURAH AGUNG KRESNA
-- STUDENT ID: 11164605

INSERT INTO Bonus(Bonus, Description)
VALUES
('Chance 1', 'Pay each of the other players £50'),
('Chance 2', 'Move forward 3 spaces'),
('Community Chest 1', 'For winning a Beauty Contest, you win £100'),
('Community Chest 2', 'Your library books are overdue. Pay a fine of £30'),
('Free Parking', 'No action'),
('Go to Jail', 'Go to Jail, do not pass GO, do not collect £200'),
('GO', 'Collect £200'),
('Jail', 'Must roll a 6 to get out');

INSERT INTO Token(Token)
VALUES
('Dog'),
('Car'),
('Battleship'),
('Top Hat'),
('Thimble'),
('Boot');

INSERT INTO Colour(Colour)
VALUES
('Orange'),
('Blue'),
('Yellow'),
('Green');


INSERT INTO Location (LocationID)
VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9),
(10),
(11),
(12),
(13),
(14),
(15),
(16);

INSERT INTO BonusLocation(BonusID, LocationID)
VALUES
(1, 2),
(2, 10),
(3, 6),
(4, 14),
(5, 8),
(6, 12),
(7, 16),
(8, 4);

INSERT INTO Player (Player, TokenID, BankBalance, LocationID)
VALUES
('Mary', 3, 190, 8),
('Bill', 1, 500, 11),
('Jane', 2, 150, 13),
('Norman', 5, 250, 1);

INSERT INTO Property (Property, Cost, ColourID, OwnerID)
VALUES
('Oak House', 100, 1,4),
('Owens Park', 30, 1,4),
('AMBS', 400, 2, NULL),
('Co-Op', 30, 2,3),
('Killburn', 120, 3, NULL),
('Uni Place', 100, 3,1),
('Victoria', 75, 4,2),
('Piccadilly', 35, 4, NULL);

INSERT INTO PropertyLocation(PropertyID, LocationID)
VALUES
(1, 9),
(2, 11),
(3, 13),
(4, 15),
(5, 1),
(6, 3),
(7, 5),
(8, 7);

