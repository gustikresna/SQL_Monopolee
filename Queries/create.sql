-- NAME: I GUSTI NGURAH AGUNG KRESNA
-- STUDENT ID: 11164605

-- ----------------------------------------- CREATING TABLES ----------------------------------------------
CREATE TABLE Bonus (
	BonusID INTEGER PRIMARY KEY AUTOINCREMENT,
	Bonus VARCHAR(30) NOT NULL UNIQUE,
	Description VARCHAR(100) NOT NULL
	);

CREATE TABLE Token(
    TokenID INTEGER PRIMARY KEY AUTOINCREMENT,
    Token VARCHAR(30) NOT NULL UNIQUE
    );

CREATE TABLE Colour(
    ColourID INTEGER PRIMARY KEY AUTOINCREMENT,
    Colour VARCHAR(30) NOT NULL UNIQUE
    );

CREATE TABLE Location(
	LocationID INTEGER PRIMARY KEY AUTOINCREMENT CHECK(LocationID <= 16) -- 16 spaces on board
	);

CREATE TABLE BonusLocation(
    BonusID INTEGER NOT NULL UNIQUE,
	LocationID INTEGER NOT NULL UNIQUE,
    FOREIGN KEY(BonusID) REFERENCES Bonus(BonusID),
    FOREIGN KEY(LocationID) REFERENCES Location(LocationID)
	);

CREATE TABLE Player (
	PlayerID INTEGER PRIMARY KEY AUTOINCREMENT CHECK(PlayerID <= 6), -- max 6 players
	Player VARCHAR(30) NOT NULL,
	TokenID INTEGER NOT NULL UNIQUE, -- using only provided token
	BankBalance INTEGER NOT NULL DEFAULT 200, -- default bank balance is 200 if not provided
	IsPlaying BOOLEAN NOT NULL DEFAULT 1, -- yes 1, no 0
    LocationID INTEGER NOT NULL DEFAULT 1, -- location 1 is the start point if no information provided
    FOREIGN KEY(TokenID) REFERENCES Token(TokenID)
	FOREIGN KEY(LocationID) REFERENCES Location(LocationID)
	);

CREATE TABLE Property (
	PropertyID INTEGER PRIMARY KEY AUTOINCREMENT,
	Property VARCHAR(30) UNIQUE NOT NULL,
	Cost INTEGER NOT NULL,
	ColourID INTEGER NOT NULL,
	OwnerID INT,
    FOREIGN KEY(ColourID) REFERENCES Colour(ColourID),
	FOREIGN KEY(OwnerID) REFERENCES Player(PlayerID)
	);

CREATE TABLE PropertyLocation(
    PropertyID INTEGER NOT NULL UNIQUE,
	LocationID INTEGER NOT NULL UNIQUE,
    FOREIGN KEY(PropertyID) REFERENCES Property(PropertyID),
    FOREIGN KEY(LocationID) REFERENCES Location(LocationID)
	);

CREATE TABLE GameRound(
	Game INTEGER PRIMARY KEY AUTOINCREMENT ,
	CurrentPlayerID INTEGER NOT NULL,
	DiceRoll INTEGER NOT NULL CHECK (DiceRoll <= 12), -- max dice roll is 12 since rolling 6 will get another roll
	FOREIGN KEY (CurrentPlayerID) REFERENCES Player(PlayerID)
	);

CREATE TABLE AuditTrail(
    Game INTEGER NOT NULL,
    PlayerID INTEGER NOT NULL,
    Player VARCHAR(30) NOT NULL,
    IsPlaying BOOLEAN NOT NULL,
    LocationLandedOn VARCHAR(30) NOT NULL,
    CurrentBankBalance INTEGER NOT NULL,
    UNIQUE(Game, PlayerID),
    FOREIGN KEY (Game) REFERENCES GameRound(Game),
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID)
);



-- --------------------------------------- CREATING TRIGGERS ----------------------------------------------

-- updating player's location for each game play
CREATE TRIGGER UpdateLocation
AFTER INSERT ON GameRound
FOR EACH ROW
BEGIN
    UPDATE Player
    SET LocationID =
        CASE
            -- maximum space is 16
            WHEN (LocationID + NEW.DiceRoll > 16)
                THEN (LocationID + NEW.DiceRoll)-16

            -- when player lands on "Chance 2"
            WHEN (LocationID + NEW.DiceRoll = 10) 
                THEN
                    CASE
                        WHEN (LocationID + NEW.DiceRoll + 3 > 16)
                            THEN (LocationID + NEW.DiceRoll + 3 - 16)
                        ELSE (LocationID + NEW.DiceRoll + 3)
                    END
                    
            -- when player lands on "Go to Jail"
            WHEN (LocationID + NEW.DiceRoll = 12) 
                THEN 4
            
            -- when player in Jail they need to roll 6 to get out
            WHEN LocationID = 4
                THEN
                    CASE
                        WHEN NEW.DiceRoll <6
                            THEN LocationID
                        -- when player get 6, the movement is the second roll
                        ELSE (LocationID + NEW.DiceRoll) - 6                           
                    END
                    
            ELSE (LocationID + NEW.DiceRoll)
                
        END
    WHERE PlayerID = NEW.CurrentPlayerID;
END;


-- player lands on property
CREATE TRIGGER LandsOnProperty
AFTER UPDATE OF LocationID ON Player
FOR EACH ROW
BEGIN
	-- 1. Update owner's bank balance from rent fee only if property has owner
    UPDATE Player
    SET BankBalance =
        -- Check if location is a property
        CASE
            WHEN(SELECT EXISTS (
                    SELECT * FROM PropertyLocation Pl
					WHERE Pl.LocationID = NEW.LocationID))
            THEN
                CASE
                    -- property has owner
                    WHEN (SELECT Pr.OwnerID FROM Property Pr
                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                            WHERE Pl.LocationID = NEW.LocationID) IS NOT NULL
                        THEN
                            CASE
                                -- owner owns all properties of certain colour (double rent fees)
                                WHEN (SELECT EXISTS (
                                        SELECT COUNT(ColourID) FROM Property
                                        WHERE OwnerID = (SELECT Pr.OwnerID FROM Property Pr
                                                        INNER JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                        WHERE Pl.LocationID = NEW.LocationID)
                                        GROUP BY ColourID
                                        HAVING COUNT(ColourID) = 2))					
                                    THEN
                                        CASE
                                            -- check if player's bank balance is sufficient
                                            WHEN NEW.BankBalance >= 
                                                    (SELECT Pr.Cost FROM Property Pr
                                                        LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                        WHERE Pl.LocationID = NEW.LocationID) * 2 -- paying double rent fees
                                                -- owner receive rent payment
                                                THEN BankBalance +  (SELECT Pr.Cost FROM Property Pr
                                                                        LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                                        WHERE Pl.LocationID = NEW.LocationID) * 2
                                            -- when player's bank balance is insufficient, owner receive player's remaining balance 
                                            ELSE BankBalance +  (SELECT P.BankBalance FROM Player P
                                                                WHERE P.PlayerID = NEW.PlayerID)
                                        END
                                
                                -- owner only owns partial property of certain colour (standard rent fee)
                                ELSE
                                    CASE
                                        -- check if player's bank balance is sufficient
                                        WHEN NEW.BankBalance >= 
                                                    (SELECT Pr.Cost FROM Property Pr
                                                        LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                        WHERE Pl.LocationID = NEW.LocationID) 
                                        -- owner receive rent payment
                                            THEN BankBalance +  (SELECT Pr.Cost FROM Property Pr
                                                                    LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                                    WHERE Pl.LocationID = NEW.LocationID)
                                        -- when player's bank balance is insufficient, owner receive player's remaining balance
                                        ELSE BankBalance + (SELECT P.BankBalance FROM Player P
                                                                WHERE P.PlayerID = NEW.PlayerID)
                                    END
                                END
                        -- if property has no owner, owner's bank balance is not updated
                        ELSE BankBalance
                END
            ELSE BankBalance
        END
    -- playerID refers to the property owner on which player is landing
    WHERE PlayerID = (SELECT Pr.OwnerID FROM Property Pr
                        INNER JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                        WHERE Pl.LocationID = NEW.LocationID);			

    -- 2. Update current player's bank balance for renting or buying property									
    UPDATE Player
    SET BankBalance =
        -- Check if location is a property
        CASE
            WHEN (SELECT EXISTS (
                    SELECT * FROM PropertyLocation Pl
					WHERE Pl.LocationID = NEW.LocationID))
                THEN
                    CASE
                        -- property has no owner (player should buy the property)
                        WHEN (SELECT Pr.OwnerID FROM Property Pr
                                LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                WHERE Pl.LocationID = NEW.LocationID) IS NULL                                          
                            THEN
                                CASE
                                    -- checking current player's bank balance
                                    WHEN NEW.BankBalance >= (SELECT Pr.Cost FROM Property Pr
                                                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                            WHERE Pl.LocationID = NEW.LocationID)
                                        -- current player's bank balance is deducted to buy property
                                        THEN BankBalance - (SELECT Pr.Cost FROM Property Pr
                                                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                            WHERE Pl.LocationID = NEW.LocationID)

                                    -- if it is insufficient
                                    -- current player's bank balance will be deducted to 0											
                                    ELSE 0
                                END

                        -- property has owner (player should pay rent)
                        WHEN (SELECT Pr.OwnerID FROM Property Pr
                                LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                WHERE Pl.LocationID = NEW.LocationID) IS NOT NULL
                            THEN
                                CASE
                                    -- owner owns all properties of certain colour (double rent fees)
                                    WHEN (SELECT EXISTS (
                                            SELECT COUNT(ColourID) FROM Property
                                            WHERE OwnerID = (SELECT Pr.OwnerID FROM Property Pr
                                                            INNER JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                            WHERE Pl.LocationID = NEW.LocationID)
                                            GROUP BY ColourID
                                            HAVING COUNT(ColourID) = 2))
                                        THEN
                                            CASE
                                                -- checking current player's bank balance
                                                WHEN NEW.BankBalance >= 
                                                            (SELECT Pr.Cost FROM Property Pr
                                                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                            WHERE Pl.LocationID = NEW.LocationID) * 2
                                                -- reducing current player's bank balance to pay double rent
                                                THEN BankBalance -  (SELECT Pr.Cost FROM Property Pr
                                                                    LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                                    WHERE Pl.LocationID = NEW.LocationID) * 2
                                                -- if the bank balance is insufficient, player gives up all their balance
                                                ELSE 0
                                            END
                                        
                                    -- owner only owns partial property of certain colour (standard rent fees)
                                    ELSE
                                        CASE
                                            -- checking current player's bank balance
                                            WHEN NEW.BankBalance >= 
                                                        (SELECT Pr.Cost FROM Property Pr
                                                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                            WHERE Pl.LocationID = NEW.LocationID) 
                                            -- reducing current player's bank balance to pay standard rent
                                            THEN BankBalance -  (SELECT Pr.Cost FROM Property Pr
                                                                    LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                                                    WHERE Pl.LocationID = NEW.LocationID)
                                            -- if the bank balance is insufficient, player gives up all their balance
                                            ELSE 0
                                        END
                                END
                        ELSE BankBalance
                    END
            ELSE BankBalance
        END      
    -- refers to current playerID
    WHERE PlayerID = NEW.PlayerID;
			
    -- 3. Update ownerID if player successfully buy property only if property has no owner
    UPDATE Property
    SET OwnerID =
        CASE
            -- checking if property has no owner
            WHEN (SELECT Pr.OwnerID FROM Property Pr
                    LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                    WHERE Pl.LocationID = NEW.LocationID) IS NULL
                
                THEN
                    CASE
                        -- checking current player's bank balance
                        WHEN NEW.BankBalance >= 
                                        (SELECT Pr.Cost FROM Property Pr
                                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                                            WHERE Pl.LocationID = NEW.LocationID)
                            -- set ownerID to current PlayerID
                            THEN NEW.PlayerID
                        -- keep NULL if player has insufficient bank balance
                        ELSE  NULL
                    END
            -- if property has owner, keep the OwnerID
            ELSE (SELECT Pr.OwnerID FROM Property Pr
                    LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                    WHERE Pl.LocationID = NEW.LocationID)
        END
    WHERE PropertyID = (SELECT Pr.PropertyID FROM Property Pr
                            LEFT JOIN PropertyLocation Pl ON Pr.PropertyID = Pl.PropertyID
                            WHERE Pl.LocationID = NEW.LocationID);
											
END;



-- player lands on bonus
CREATE TRIGGER GetBonus
AFTER UPDATE OF LocationID ON Player
FOR EACH ROW
BEGIN
	-- update current player's bank balance associated with bonus
	UPDATE Player
	SET BankBalance =
        CASE
            -- checking if the location is bonus
            WHEN (SELECT EXISTS (
                    SELECT * FROM BonusLocation Bl
					WHERE Bl.LocationID = NEW.LocationID))
                THEN
                    CASE
                        -- when player lands on "Chance 1"
                        WHEN NEW.LocationID = 2
                            THEN
                                CASE
                                    WHEN NEW.BankBalance >= 50*3
                                    THEN BankBalance - 50*3
                                    ELSE 0
                                END
                        -- when player lands on "Community Chest 1"
                        WHEN NEW.LocationID = 6
                            THEN BankBalance + 100
                        
                        -- when player lands on "Community Chest 2"
                        WHEN NEW.LocationID = 14
                            THEN
                                CASE
                                    WHEN NEW.BankBalance >= 30
                                    THEN BankBalance - 30
                                    ELSE 0
                                END							                      
                        -- else, keep current bank balance
                        ELSE BankBalance
                    END
            ELSE BankBalance
        END
	WHERE PlayerID = NEW.PlayerID;

    -- update when player lands or passes GO (except for going to jail)
    UPDATE Player
    SET BankBalance =
        CASE
            WHEN (SELECT EXISTS (
                    SELECT * FROM BonusLocation Bl
                    WHERE Bl.LocationID = NEW.LocationID))
                THEN
                    CASE
                        WHEN (NEW.LocationID = 16 OR  NEW.LocationID < OLD.LocationID) AND (NEW.LocationID != 4)
                            THEN BankBalance + 200
                        ELSE BankBalance
                    END
            ELSE BankBalance
        END
    WHERE PlayerID = NEW.PlayerID;

	-- update other's player balance (for Chance 1)
	UPDATE Player
	SET BankBalance =
        CASE
            -- Chance 1
            WHEN NEW.LocationID = 2
                THEN
                    CASE
                        WHEN NEW.BankBalance >= 50*3
                            THEN BankBalance + 50
                        -- if current player's bank balance is insufficient,
                        -- all their remaining balance will be distributed evenly to the other players
                        ELSE BankBalance + NEW.BankBalance / 3
                    END
            ELSE BankBalance
        END
    -- all but the current player
	WHERE PlayerID != NEW.PlayerID;

END;


-- updating current player's playing status (IsPlaying)
CREATE TRIGGER UpdatePlayerPlayingStatus
AFTER UPDATE OF BankBalance ON Player
FOR EACH ROW
BEGIN
    -- when bank balance become 0, Player is bankrupt hence 0
    UPDATE Player
    SET IsPlaying= 
            CASE
                WHEN BankBalance = 0
                THEN 0
                ELSE 1
            END
    WHERE PlayerID = NEW.PlayerID;
END;

-- audit trail
CREATE TRIGGER Audit
AFTER UPDATE OF IsPlaying ON Player
FOR EACH ROW
BEGIN
	INSERT OR REPLACE INTO AuditTrail(Game, PlayerID, Player, IsPlaying, LocationLandedOn, CurrentBankBalance)
	SELECT 
    (SELECT Game FROM GameRound ORDER BY Game DESC LIMIT 1),
    P.PlayerID, P.Player, P.IsPlaying,
	COALESCE(Pr.Property, B.Bonus) ,
     P.BankBalance
	FROM Player P
    LEFT JOIN GameRound G ON P.PlayerID = G.CurrentPlayerID
	LEFT JOIN PropertyLocation Pl ON P.LocationID = Pl.LocationID
	LEFT JOIN BonusLocation Bl on P.LocationID = Bl.LocationID
	LEFT JOIN Property Pr ON Pl.PropertyID = Pr.PropertyID
	LEFT JOIN Bonus B ON Bl.BonusID = B.BonusID;
END;
	
