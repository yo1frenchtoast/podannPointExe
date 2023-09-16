using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum PuzzleObjectType
{
	SCENEOBJECT = 0x0,
	INVENTORYOBJECT,
	COUNT
}

[System.Serializable]
public class PuzzleItemCombination
{
	public PuzzleObject puzzleAssociation;
	//No longer used
	public string response;
	public bool isAGoodCombination;
}

[CreateAssetMenu(fileName = "PuzzleObject", menuName = "PuzzleObject/CreateNewPuzzleObject", order = 1)]
public class PuzzleObject : ScriptableObject
{
	// Puzzle object specific informations
	private int clickCounter = 0;

	[SerializeField]
	private PuzzleObjectType objectType = PuzzleObjectType.SCENEOBJECT;
	[SerializeField]
	private string[] messageFeedbacks = { "Hello, I'm a puzzle object, how are you doing?" };
	[SerializeField]
	private AudioClip[] audioFeedbacks = null;
	[SerializeField]
	private GameObject[] particleFeedbacks = null;
	[SerializeField]
	private PuzzleItemCombination[] combinationResponses = null;
	[SerializeField]
	private bool succeedsAutomatically = false;
	[SerializeField]
	private PuzzleObject succeedPuzzleObject = null;

	public PuzzleObjectType ObjectType
	{
		get { return objectType; }
	}
	public string InteractMessage
	{
		get
		{
			if(messageFeedbacks != null && messageFeedbacks.Length > 0)
				return messageFeedbacks[clickCounter % messageFeedbacks.Length];
			return null;
		}
		set
		{
			messageFeedbacks[0] = value;
		}
	}

	public AudioClip AudioFeedback
	{
		get
		{
			if(audioFeedbacks != null && audioFeedbacks.Length > 0)
				return audioFeedbacks[clickCounter % audioFeedbacks.Length];
			return null;
		}
	}

	public GameObject SpawnableParticle
	{
		get 
		{
			if(particleFeedbacks != null && particleFeedbacks.Length > 0)
				return particleFeedbacks[clickCounter % particleFeedbacks.Length];
			return null;
		}
	}

	public bool SucceedsAutomatically
	{
		get { return succeedsAutomatically; }
	}

	public PuzzleObject SucceedPuzzleObject
	{
		get { return succeedPuzzleObject; }
	}
	
	//Object informations to populate gameobject data
	public string objectName = "Puzzle Object";
	public Sprite representation = null;
	public Animator representationAnimatior = null;

	public void IncreaseClickCounter()
	{
		clickCounter++;
	}

	public void ResetCounter()
	{
		clickCounter = 0;
	}

	public PuzzleItemCombination TestCombination (PuzzleObject toTest)
	{
		if (toTest != null)
		{
			foreach (PuzzleItemCombination comb in combinationResponses)
			{
				if (comb.puzzleAssociation == toTest)
					return comb;
			}
		}
		return null;
	}
}
