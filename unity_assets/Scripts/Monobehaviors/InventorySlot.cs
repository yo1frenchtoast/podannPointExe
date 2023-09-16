using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class InventorySlot : MonoBehaviour
{
	private PuzzleObject slotObject;
	[SerializeField]
	private Button slotButton;
	[SerializeField]
	private int slotIndex = 0;

	public PuzzleObject SlotObject
	{
		set { slotObject = value; }
	}

	public int SlotIndex
	{
		get { return slotIndex; }
		set { slotIndex = value; }
	}
}
