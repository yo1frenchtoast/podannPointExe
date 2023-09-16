using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Cinemachine;

public class CameraControl : MonoBehaviour
{
    public Camera cameraRef = null;
    public Vector3 lockDistance = Vector3.zero;
    private Vector3 lockPosition = Vector3.zero;
    public bool[] lockAxis = new bool[3] { false, false, false };

    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        LockAxis();
    }

    private void LateUpdate()
    {
        transform.position = lockPosition;
    }

    // Lock axis
    void LockAxis()
    {
        lockPosition = Input.mousePosition;
        lockPosition = (new Vector3(lockAxis[0] == true ? lockDistance.x : lockPosition.x, lockAxis[1] == true ? lockDistance.y : lockPosition.y, lockAxis[2] == true ? lockDistance.z : lockPosition.z));
        lockPosition = cameraRef.ScreenToWorldPoint(lockPosition, Camera.MonoOrStereoscopicEye.Right);
        //Debug.Log("before lock " + lockPosition);
 
        lockPosition = (new Vector3(lockAxis[0] == true ? lockDistance.x : lockPosition.x, lockAxis[1] == true ? lockDistance.y : lockPosition.y, lockAxis[2] == true ? lockDistance.z : lockPosition.z));
        //Debug.Log("raw " + Input.mousePosition);
        //Debug.Log("after lock " + lockPosition);
    }
}
