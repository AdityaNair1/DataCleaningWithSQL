/* Data cleaning through SQL
Using the following queries to clean the Nashville housing dataset */

Select * 
From Data_Cleaning.dbo.NashvilleHousingData

-- Standardizing Date Format (SaleDate)

Select SaleDate
From NashvilleHousingData

Update NashvilleHousingData
Set SaleDate = Convert(date, SaleDate) -- Primary approach

Alter Table NashvilleHousingData 
Add SaleDateConverted Date;

Update NashvilleHousingData
Set SaleDateConverted = Convert(date, SaleDate) -- Alternate Approach 

Select SaleDateConverted 
From NashvilleHousingData;

-- Populate missing PropertyAdress rows

Select PropertyAddress
from NashvilleHousingData
where PropertyAddress is null

-- Using self join to identify the missing address and populating it.

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as PropertyAddressFinal
From NashvilleHousingData as a
JOIN NashvilleHousingData as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] 
	where a.PropertyAddress is null 

Update a
SET propertyaddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousingData as a 
JOIN NashvilleHousingData as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] 
	where a.PropertyAddress is null 

/*Splitting out the PropertyAddress and OwnerAddress columns using PARSENAME and SUBSTRING 
to get individula columns such as Address, City, State */

Select PropertyAddress 
from NashvilleHousingData

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as CityORTown
From NashvilleHousingData

Alter Table NashvilleHousingData 
Add PropertyStreetAddress nvarchar(255);

Update NashvilleHousingData
Set PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter Table NashvilleHousingData 
Add PropertyAddressCity nvarchar(255);

Update NashvilleHousingData
Set PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

Select 
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3) as OwnerStreetAddress,
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2) as OwnerAddressCity,
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1) as OwnerAddressState
From NashvilleHousingData

Alter Table NashvilleHousingData 
Add OwnerStreetAddress nvarchar(255);

Update NashvilleHousingData
Set OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3) 

Alter Table NashvilleHousingData 
Add OwnerAddressCity nvarchar(255);

Update NashvilleHousingData
Set OwnerAddressCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2)

Alter Table NashvilleHousingData 
Add OwnerAddressState nvarchar(255);

Update NashvilleHousingData
Set OwnerAddressState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)

-- Harmonizing the SoldAsVacant column by reassigning the rows that show 'Y' and 'N' as 'Yes' and 'No'

Select Distinct SoldAsVacant, Count(SoldAsVacant)
From NashvilleHousingData
group by SoldAsVacant

Select SoldAsVacant,
	Case when SoldAsVacant = 'Y' then 'Yes'
		 when SoldAsVacant = 'N' then 'No'
		 ELSE SoldAsVacant
		 END as SoldAsVacant_cleaned
From NashvilleHousingData

Update NashvilleHousingData
Set SoldAsVacant = Case when SoldAsVacant = 'Y' then 'Yes'
		 when SoldAsVacant = 'N' then 'No'
		 ELSE SoldAsVacant
		 END 

-- Removing duplicates


WITH Row_Num_CTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
From NashvilleHousingData
)
Delete 
from Row_Num_CTE
where row_num >1


-- Deleting Unused Columns

Alter Table NashvilleHousingData
Drop Column SaleDate, OwnerAddress, PropertyAddress

Select * from NashvilleHousingData