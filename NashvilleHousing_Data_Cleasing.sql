/*
Cleaning Data in SQL Queries
*/

Select *
	From PorfolioProjects..NashvilleHousing

-- Standardize Date Format

Alter Table PorfolioProjects..NashvilleHousing
	Alter Column SaleDate Date


-- Populate Property Address Data

Update A
Set PropertyAddress = Isnull(A.PropertyAddress,B.PropertyAddress)
From PorfolioProjects..NashvilleHousing as A
Join PorfolioProjects..NashvilleHousing as B
	On A.ParcelID = B.ParcelID
	And A.[UniqueID ]<> B.[UniqueID ]
Where A.PropertyAddress is null


-- Breaking out PropertyAddress and OwnerAddress into Columns (Address, City and State)

Alter Table PorfolioProjects..NashvilleHousing
	Add PropertySplitAddress Nvarchar(255)
	Go

Update PorfolioProjects..NashvilleHousing
	Set PropertySplitAddress = Left(PropertyAddress, CharIndex(',',PropertyAddress)-1)

Alter Table PorfolioProjects..NashvilleHousing
	Add PropertySplitCity Nvarchar(255)
	Go

Update PorfolioProjects..NashvilleHousing
	Set PropertySplitCity = Right(PropertyAddress,Len(PropertyAddress) - CharIndex(',',PropertyAddress)-1)

Alter Table PorfolioProjects..NashvilleHousing
	Add OwnerSplitAddress Nvarchar(255);
	Go

Update PorfolioProjects..NashvilleHousing
	Set OwnerSplitAddress = ParseName(Replace(OwnerAddress,',','.'),3)

Alter Table PorfolioProjects..NashvilleHousing
	Add OwnerSplitCity Nvarchar(255)
	Go

Update PorfolioProjects..NashvilleHousing
	Set OwnerSplitCity = ParseName(Replace(OwnerAddress,',','.'),2);

Alter Table PorfolioProjects..NashvilleHousing
	Add OwnerSplitState Nvarchar(255);
	Go

Update PorfolioProjects..NashvilleHousing
	Set OwnerSplitState = ParseName(Replace(OwnerAddress,',','.'),1);


-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PorfolioProjects..NashvilleHousing
Group by SoldAsVacant
Order by 2

Update PorfolioProjects..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- Copying Unique Values into #Temp Table

With A as
	(
	Select *, ROW_NUMBER() Over (Partition By ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference Order by UniqueID) as RowN
		From PorfolioProjects..NashvilleHousing
	)
Select * into #Temp from A
	Where RowN <2
	Order By UniqueID


-- Delete Unused Columns.

Alter Table #Temp
	Drop Column PropertyAddress, OwnerAddress, TaxDistrict, RowN

Select *
	From #Temp