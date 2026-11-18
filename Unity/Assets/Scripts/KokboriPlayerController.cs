using UnityEngine;

/// <summary>Mobile-ready third-person movement starter for the KOKBORI RP prototype.</summary>
[RequireComponent(typeof(CharacterController))]
public sealed class KokboriPlayerController : MonoBehaviour
{
    [SerializeField] private KokboriVirtualJoystick joystick;
    [SerializeField] private Transform cameraTransform;
    [SerializeField] private float moveSpeed = 4.5f;
    [SerializeField] private float rotationSpeed = 12f;
    [SerializeField] private float gravity = -20f;

    private CharacterController controller;
    private float verticalVelocity;

    private void Awake() => controller = GetComponent<CharacterController>();

    private void Update()
    {
        Vector2 input = joystick != null ? joystick.Value :
            new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));

        Vector3 forward = cameraTransform != null ? cameraTransform.forward : Vector3.forward;
        Vector3 right = cameraTransform != null ? cameraTransform.right : Vector3.right;
        forward.y = 0; right.y = 0;
        forward.Normalize(); right.Normalize();

        Vector3 move = Vector3.ClampMagnitude(forward * input.y + right * input.x, 1f);
        if (move.sqrMagnitude > 0.001f)
        {
            var target = Quaternion.LookRotation(move, Vector3.up);
            transform.rotation = Quaternion.Slerp(transform.rotation, target, rotationSpeed * Time.deltaTime);
        }

        if (controller.isGrounded && verticalVelocity < 0) verticalVelocity = -2f;
        verticalVelocity += gravity * Time.deltaTime;
        Vector3 velocity = move * moveSpeed;
        velocity.y = verticalVelocity;
        controller.Move(velocity * Time.deltaTime);
    }
}
