using System;
using UnityEngine;
using UnityEngine.EventSystems;

/// <summary>Runs callbacks while a mobile UI button is held down.</summary>
public sealed class KokboriHoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler, IPointerExitHandler
{
    private Action pressed;
    private Action released;

    public void Initialize(Action onPressed, Action onReleased)
    {
        pressed = onPressed;
        released = onReleased;
    }

    public void OnPointerDown(PointerEventData eventData) => pressed?.Invoke();
    public void OnPointerUp(PointerEventData eventData) => released?.Invoke();
    public void OnPointerExit(PointerEventData eventData) => released?.Invoke();
    private void OnDisable() => released?.Invoke();
}
