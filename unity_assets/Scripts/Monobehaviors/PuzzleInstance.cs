using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PuzzleInstance : MonoBehaviour
{
    [SerializeField]
    private PuzzleObject puzzleObject = null;
    private SpriteRenderer spriteRenderer = null;
    private Collider objectCollider = null;

    public PuzzleObject PuzzleObject
	{
        get { return puzzleObject; }
        set
		{
            if(value == null)
			{
                gameObject.SetActive(false);
			}
            else
			{
                puzzleObject = value;
                Populate();
			}
		}
	}

    void Awake()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        if (spriteRenderer == null)
            Debug.LogError("Add a sprite renderer");
        objectCollider = GetComponent<Collider>();
        if(objectCollider == null)
            Debug.LogError("Add a collider");
        if(puzzleObject != null)
            puzzleObject.ResetCounter();
		Populate();
    }

    private void Populate()
	{
        spriteRenderer.sprite = puzzleObject.representation;
        name = puzzleObject.name;
    }
}
