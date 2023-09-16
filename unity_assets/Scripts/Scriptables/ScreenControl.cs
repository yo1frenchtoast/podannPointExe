using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Cinemachine;


public class ScreenControl : MonoBehaviour
{
    public GameObject[] LookAts = null;
    // Position on screens
    public int screenIndex = 0;
    // Nav buttons
    public Button btnLeft, btnRight;

    public Text title;

    private int weatherIndex = 0;
    public GameObject weatherBackground;
    public Sprite[] weatherSprites;

    // Start is called before the first frame update
    void Start()
    {
        btnLeft.onClick.AddListener(() => ChangeScreen("left"));
        btnRight.onClick.AddListener(() => ChangeScreen("right"));
    }

    // Update is called once per frame
    void Update()
    {
        // Disable left button if on far left screen
        // where screenIndex[0] = intro
        if (screenIndex <= 1)
        {
            btnLeft.gameObject.SetActive(false);
        }
        // Disable right button if on far right screen
        else if (screenIndex == LookAts.Length - 1)
        {
            btnRight.gameObject.SetActive(false);
        }
        // Display both buttons by default
        else
        {
            btnLeft.gameObject.SetActive(true);
            btnRight.gameObject.SetActive(true);
        }
    }

    void ChangeScreen(string direction)
    {
        // Move to left
        if (String.Equals(direction, "left"))
        {
            screenIndex--;
            // Avoid getting outbound of array and back to intro 
            if (screenIndex < 1)
            {
                screenIndex = 1;
            }
            // Force virutal cam to follow next left screen
            LoadScreen(LookAts[screenIndex]);
        }
        // Move to right
        else if (String.Equals(direction, "right"))
        {
            screenIndex++;
            // Avoid getting outbound of array
            if (screenIndex >= LookAts.Length)
            {
                screenIndex = LookAts.Length - 1;
            }
            // Force virutal cam to follow next right screen
            LoadScreen(LookAts[screenIndex]);
        }
    }

    // Load screen
    void LoadScreen(GameObject Screen)
    {
        // Load virtual cam
        CinemachineVirtualCamera VCam = FindObjectOfType<CinemachineVirtualCamera>();

        // Weather screen
        if (screenIndex == 3)
        {
            CycleWeatherScreen();
        }
        else
        {
            VCam.Follow = Screen.transform;
        }
    }

    // Cycle "temps" screen
    void CycleWeatherScreen()
    {
        // Load virtual cam
        CinemachineVirtualCamera VCam = FindObjectOfType<CinemachineVirtualCamera>();

        // Load sprite in 'sunny, cloudy, rainy' order
        weatherBackground.GetComponent<SpriteRenderer>().sprite = weatherSprites[weatherIndex];
        weatherIndex = (weatherIndex + 1) % weatherSprites.Length;
      
        VCam.Follow = LookAts[3].transform;
    }
}
