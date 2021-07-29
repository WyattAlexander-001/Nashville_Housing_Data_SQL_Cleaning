/*

"Process to Clean Data In SQL"

Data set: https://github.com/AlexTheAnalyst/PortfolioProjects/blob/main/Nashville%20Housing%20Data%20for%20Data%20Cleaning.xlsx

*/

--First Check Data

Select *
From HousingInfoYT.dbo.NashvilleHousing
-------------------------------------------------------------------------------------------

--Standardize Date Format (Remove Time)
--Herew we can see there's this 00:00:00:000 time here, we don't need that so we can just remove it with the following steps:

Select SaleDate
From HousingInfoYT.dbo.NashvilleHousing

--1st, alter your table to have a NEW COLUMN, running this query again will result in an error as we already created a NEW COLUMN
Alter Table NashvilleHousing
Add SaleDateConverted Date;

--2nd update the existing table, setting the new column from step 1 with your new adjustments
Update NashvilleHousing
Set SaleDateConverted = Convert(Date,SaleDate)

--3rd CHeck your new column! THere's no more 00:00:00:000!
Select saleDateConverted
From HousingInfoYT.dbo.NashvilleHousing


-------------------------------------------------------------------------------------------

--Populate Property Address

--We have NULL values, they have to be cleaned
--There are null values where the address from the same ParcelID could be subbed in

--Join table onto itself
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From HousingInfoYT.dbo.NashvilleHousing a
Join HousingInfoYT.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	And a.[UniqueID] <> b.[UniqueID ]
Where a.PropertyAddress is null

--Now Update
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From HousingInfoYT.dbo.NashvilleHousing a
Join HousingInfoYT.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	And a.[UniqueID] <> b.[UniqueID ]
Where a.PropertyAddress is null

--CHeck if the nulls are gone by running the same Select Query

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From HousingInfoYT.dbo.NashvilleHousing a
Join HousingInfoYT.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	And a.[UniqueID] <> b.[UniqueID ]
Where a.PropertyAddress is null


-------------------------------------------------------------------------------------------
-- Breaking Out Address into individual columns (Address, City, State)

Select PropertyAddress 
From HousingInfoYT.dbo.NashvilleHousing 


-- Run this and the above query, and you will see it cuts off everything to the RIGHT of the comma
-- The 2nd stubstring is here REMOVE the comma, you can now just run this query for the desired result

Select
Substring(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1) as Address
, Substring(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress)) as City
From HousingInfoYT.dbo.NashvilleHousing 

-- Now we can Alter/Update our table like before, Nvarchar(255) accounts for large string values
-- First run alter, then update

Alter Table NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
Set PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',' , PropertyAddress) -1)

Alter Table NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
Set PropertySplitCity = Substring(PropertyAddress, CHARINDEX(',' , PropertyAddress) +1, LEN(PropertyAddress))

--Verify by selecting all and checking the newly added columns at the end

Select *
From HousingInfoYT.dbo.NashvilleHousing 


-------------------------------------------------------------------------------------------
-- Breaking up Owner Address into individual columns with a different approach

Select OwnerAddress
From HousingInfoYT.dbo.NashvilleHousing 


--Parsename parses using periods, we can simply replace the commas with a period and then parse.
--We order in reverse (3,2,1) because PARSENAME parses backwords
Select
PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3) as US_Street
,PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2) as US_City
,PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1) as US_State
From HousingInfoYT.dbo.NashvilleHousing 

--Now to Alter/Update table, run alter THEN run update

Alter Table NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,3)

Alter Table NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,2)

Alter Table NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',' , '.') ,1) 


--Check work
Select *
From HousingInfoYT.dbo.NashvilleHousing 
-------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

--This checks the total values in this field. We have a mix of Yes,Y,No, and N. We just want boolean/binary values, YES/NO or Y/N.
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From HousingInfoYT.dbo.NashvilleHousing 
Group by SoldAsVacant
order by 2

--Use a case statement (similar to an if/elif/else statement) to change Y/N to Yes/No
Select SoldAsVacant
, CASE when SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
From HousingInfoYT.dbo.NashvilleHousing 

Update NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

--Check work
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From HousingInfoYT.dbo.NashvilleHousing 
Group by SoldAsVacant
order by 2
-------------------------------------------------------------------------------------------

--Remove Duplicates (Redundant data)

WITH RowNumCTE As(
Select *,
	ROW_NUMBER() Over (
	PARTITION BY ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		Order by
			UniqueID
			) row_num
From HousingInfoYT.dbo.NashvilleHousing 
)
Delete
From RowNumCTE
Where row_num > 1


-------------------------------------------------------------------------------------------

--Delete Unused Columns

Select *
From HousingInfoYT.dbo.NashvilleHousing 

--We are altering the table by dropping what we don't need anymore. DON'T DO THIS TO THE RAW DATA TABLE
ALTER TABLE HousingInfoYT.dbo.NashvilleHousing 
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

--Check work
Select *
From HousingInfoYT.dbo.NashvilleHousing 


-------------------------------------------------------------------------------------------

/*Data is now cleaner and more useable. To recap, we got rid of duplicates, parsed loaded columns, and dropped unneeded columns*/