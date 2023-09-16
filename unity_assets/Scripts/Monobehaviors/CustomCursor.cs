using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class CustomCursor : MonoBehaviour
{
    private List<PuzzleObject> inventory = new List<PuzzleObject>();
    private SpriteRenderer spriteRenderer = null;
    private AudioSource audioSource = null;
    private PuzzleInstance hoveredInstanced = null;
    [SerializeField]
    private Sprite noSelectionSprite = null;
    [SerializeField]
    private Text textRender = null;

    void Start()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        if (spriteRenderer == null)
            Debug.LogError(name + " should have a sprite renderer");
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
            Debug.LogError("should have an audiosource");
        spriteRenderer.sprite = noSelectionSprite;
        Cursor.visible = false;
    }

    void Update()
    {
        if(Input.GetKeyDown(KeyCode.Slash))
		{
			foreach(PuzzleObject inventoryObject in inventory)
			{
                Debug.Log(inventoryObject.objectName);
			}
		}

        Plane plane = new Plane(-Vector3.forward, new Vector3(0, 0, 10));
        float distance;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (plane.Raycast(ray, out distance))
        {
            transform.position = ray.GetPoint(distance);
        }
        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
		{
            spriteRenderer.color = Color.red;
            if (hit.collider.GetComponent<PuzzleInstance>() != null)
			{
                hoveredInstanced = hit.collider.GetComponent<PuzzleInstance>();
            }
		}
        else
        {
            hoveredInstanced = null;
            spriteRenderer.color = Color.white;
        }

        if (Input.GetMouseButtonDown(0))
		{
            ComputePuzzle();
		}
    }

    private void ComputePuzzle()
    {
        // Si on clique sur un objet
        if (hoveredInstanced != null)
        {
            // On regarde si on a pas un objet dans notre inventaire qui peut creer une reaction
            PuzzleItemCombination result = null;
            int resultNumber = -1;
            for(int i = 0; i < inventory.Count; i++)
			{
                if (hoveredInstanced.PuzzleObject.TestCombination(inventory[i]) != null)
				{
                    result = hoveredInstanced.PuzzleObject.TestCombination(inventory[i]);
                    resultNumber = i;
				}
			}
            // Si c'est le cas, dependamment de si c'est une bonne combinaison on va soit mettre l'object dans l'inventaire, soit
            // donner une reponse custom
            if(result != null)
			{
                if(result.isAGoodCombination)
				{
                    switch (hoveredInstanced.PuzzleObject.SucceedPuzzleObject.ObjectType)
                    {
                        case PuzzleObjectType.INVENTORYOBJECT:
                            inventory[resultNumber] = hoveredInstanced.PuzzleObject.SucceedPuzzleObject;
                            GetPuzzleObjectResponse(inventory[resultNumber]);
                            hoveredInstanced.PuzzleObject = null;
                            hoveredInstanced = null;
                            break;
                        case PuzzleObjectType.SCENEOBJECT:
                            hoveredInstanced.PuzzleObject = hoveredInstanced.PuzzleObject.SucceedPuzzleObject;
                            GetPuzzleObjectResponse(hoveredInstanced.PuzzleObject);
                            break;
                        case PuzzleObjectType.COUNT:
                        default:
                            break;
                    }
                }
                else
				{
                    GetPuzzleObjectResponseNoDialogBox(hoveredInstanced.PuzzleObject);
                    textRender.text = result.response;

                }
			}
            else
			{
                // Sinon on regarde si on a un success automatique
                if (hoveredInstanced.PuzzleObject.SucceedsAutomatically)
                {
                    hoveredInstanced.PuzzleObject = hoveredInstanced.PuzzleObject.SucceedPuzzleObject;
                    if (hoveredInstanced != null)
                    {
                        // Si notre objet de succes automatique est un objet inventaire
                        switch (hoveredInstanced.PuzzleObject.ObjectType)
                        {
                            case PuzzleObjectType.INVENTORYOBJECT:
                                for (int i = 0; i < inventory.Count; i++)
                                {
                                    // On regarde si on peut le combiner
                                    if (inventory[i].TestCombination(hoveredInstanced.PuzzleObject) != null && inventory[i].TestCombination(hoveredInstanced.PuzzleObject).isAGoodCombination)
                                    {
                                        result = inventory[i].TestCombination(hoveredInstanced.PuzzleObject);
                                        inventory[i] = result.puzzleAssociation;
                                        GetPuzzleObjectResponse(inventory[i]);
                                        hoveredInstanced.PuzzleObject = null;
                                        hoveredInstanced = null;
                                        return;
                                    }
                                }
                                //Autrement on l'ajoute a notre inventaire
                                inventory.Add(hoveredInstanced.PuzzleObject);
                                GetPuzzleObjectResponse(inventory[inventory.Count-1]);
                                hoveredInstanced.PuzzleObject = null;
                                hoveredInstanced = null;
                                return;
                            case PuzzleObjectType.SCENEOBJECT:
                                break;
                            case PuzzleObjectType.COUNT:
                            default:
                                break;
                        }
                    }
                }
                GetPuzzleObjectResponse(hoveredInstanced.PuzzleObject);
            }
        }
    }

    private void GetPuzzleObjectResponse(PuzzleObject ToRespond)
	{
        audioSource.Stop();
        audioSource.clip = ToRespond.AudioFeedback;
        if (audioSource.clip != null)
        {
            audioSource.Play();
        }
        textRender.text = ToRespond.InteractMessage;
        GameObject spawnable = ToRespond.SpawnableParticle;
        if (spawnable != null)
        {
            Instantiate(spawnable, hoveredInstanced.transform.position, Quaternion.identity);
        }
        ToRespond.IncreaseClickCounter();
    }

    private void GetPuzzleObjectResponseNoDialogBox(PuzzleObject ToRespond)
    {
        audioSource.Stop();
        audioSource.clip = ToRespond.AudioFeedback;
        if (audioSource.clip != null)
        {
            audioSource.Play();
        }
        textRender.text = ToRespond.InteractMessage;
        GameObject spawnable = ToRespond.SpawnableParticle;
        if (spawnable != null)
        {
            Instantiate(spawnable, hoveredInstanced.transform.position, Quaternion.identity);
        }
        ToRespond.IncreaseClickCounter();
    }
}
