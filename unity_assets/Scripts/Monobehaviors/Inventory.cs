using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Inventory : MonoBehaviour
{
    [SerializeField]
    private InventorySlot[] inventorySlots = null;

    public void AddItem(PuzzleObject _newObject)
    {
        InventorySlot toAdd = new InventorySlot();
        toAdd.SlotObject = _newObject;
        
        for(int i = 0; i<inventorySlots.Length;i++)
		{
            if(inventorySlots[i] == null)
			{
                toAdd.SlotIndex = i;
                inventorySlots[i] = toAdd;
                i = inventorySlots.Length;
			}
		}
	}
}
