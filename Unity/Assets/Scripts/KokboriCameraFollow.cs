using UnityEngine;

/// <summary>Basic smooth follow camera. Place behind and above the player.</summary>
public sealed class KokboriCameraFollow : MonoBehaviour
{
    [SerializeField] private Transform target;
    [SerializeField] private Vector3 offset = new Vector3(0f, 4f, -6f);
    [SerializeField, Range(0.01f, 1f)] private float smooth = 0.12f;
    [SerializeField] private float lookHeight = 1.4f;

    private void LateUpdate()
    {
        if (target == null) return;
        Vector3 desired = target.position + target.rotation * offset;
        transform.position = Vector3.Lerp(transform.position, desired, smooth);
        transform.LookAt(target.position + Vector3.up * lookHeight);
    }
}
