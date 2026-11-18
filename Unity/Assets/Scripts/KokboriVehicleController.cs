using UnityEngine;

/// <summary>
/// Simple arcade vehicle for the KOKBORI greybox. The car is built from primitives,
/// so the prototype has no external asset dependencies.
/// </summary>
public sealed class KokboriVehicleController : MonoBehaviour
{
    [SerializeField] private float acceleration = 11f;
    [SerializeField] private float reverseSpeed = 7f;
    [SerializeField] private float maxSpeed = 22f;
    [SerializeField] private float steeringSpeed = 95f;

    private Transform player;
    private CharacterController character;
    private Camera followCamera;
    private float throttle;
    private float steering;
    private float speed;
    private bool driving;

    public bool IsDriving => driving;
    public float Speed => speed;

    public static KokboriVehicleController Create(Vector3 position)
    {
        var root = new GameObject("KOKBORI Sedan");
        root.transform.position = position;
        var vehicle = root.AddComponent<KokboriVehicleController>();
        vehicle.BuildCar();
        return vehicle;
    }

    private void BuildCar()
    {
        MakePart("Body", new Vector3(0, 0.72f, 0), new Vector3(2.05f, 0.65f, 4.1f), new Color(0.08f, 0.24f, 0.48f));
        MakePart("Cabin", new Vector3(0, 1.28f, -0.15f), new Vector3(1.65f, 0.8f, 2.0f), new Color(0.12f, 0.16f, 0.2f));
        MakePart("Front Glass", new Vector3(0, 1.35f, 0.88f), new Vector3(1.48f, 0.58f, 0.06f), new Color(0.25f, 0.48f, 0.58f));
        MakePart("Rear Glass", new Vector3(0, 1.35f, -1.12f), new Vector3(1.48f, 0.58f, 0.06f), new Color(0.25f, 0.48f, 0.58f));
        MakePart("Front Bumper", new Vector3(0, 0.55f, 2.08f), new Vector3(1.9f, 0.22f, 0.16f), Color.gray);
        MakePart("Rear Bumper", new Vector3(0, 0.55f, -2.08f), new Vector3(1.9f, 0.22f, 0.16f), Color.gray);
        for (int side = -1; side <= 1; side += 2)
        for (int axle = -1; axle <= 1; axle += 2)
        {
            var wheel = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            wheel.name = "Wheel";
            wheel.transform.SetParent(transform, false);
            wheel.transform.localPosition = new Vector3(side * 1.02f, 0.48f, axle * 1.32f);
            wheel.transform.localRotation = Quaternion.Euler(0, 0, 90);
            wheel.transform.localScale = new Vector3(0.78f, 0.2f, 0.78f);
            wheel.GetComponent<Renderer>().material = MakeMaterial(new Color(0.035f, 0.035f, 0.04f));
        }
    }

    private void MakePart(string partName, Vector3 localPosition, Vector3 scale, Color color)
    {
        var part = GameObject.CreatePrimitive(PrimitiveType.Cube);
        part.name = partName;
        part.transform.SetParent(transform, false);
        part.transform.localPosition = localPosition;
        part.transform.localScale = scale;
        part.GetComponent<Renderer>().material = MakeMaterial(color);
    }

    private static Material MakeMaterial(Color color)
    {
        Shader shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");
        var material = new Material(shader);
        material.color = color;
        return material;
    }

    public void SetControls(float gas, float turn)
    {
        throttle = Mathf.Clamp(gas, -1f, 1f);
        steering = Mathf.Clamp(turn, -1f, 1f);
    }

    public void ToggleDrive(Transform playerTransform, CharacterController playerController, Camera camera)
    {
        if (!driving)
        {
            if (Vector3.Distance(playerTransform.position, transform.position) > 4.2f) return;
            player = playerTransform;
            character = playerController;
            followCamera = camera;
            character.enabled = false;
            player.SetParent(transform, true);
            player.localPosition = new Vector3(0, 0.2f, -0.1f);
            player.localRotation = Quaternion.identity;
            player.gameObject.SetActive(false);
            driving = true;
        }
        else
        {
            driving = false;
            player.gameObject.SetActive(true);
            player.SetParent(null, true);
            player.position = transform.position + transform.right * 1.8f + Vector3.up * 0.15f;
            character.enabled = true;
            speed = 0;
            throttle = 0;
            steering = 0;
        }
    }

    public void Tick(float deltaTime)
    {
        if (!driving) return;
        float targetLimit = throttle >= 0 ? maxSpeed : reverseSpeed;
        speed += throttle * acceleration * deltaTime;
        speed = Mathf.Clamp(speed, -targetLimit * 0.45f, targetLimit);
        if (Mathf.Abs(throttle) < 0.01f) speed = Mathf.MoveTowards(speed, 0, 3.5f * deltaTime);
        float steerFactor = Mathf.Clamp01(Mathf.Abs(speed) / 3f);
        transform.Rotate(Vector3.up, steering * steeringSpeed * steerFactor * Mathf.Sign(speed == 0 ? 1 : speed) * deltaTime);
        transform.position += transform.forward * speed * deltaTime;
        if (followCamera != null)
        {
            Vector3 target = transform.position - transform.forward * 7f + Vector3.up * 4f;
            followCamera.transform.position = Vector3.Lerp(followCamera.transform.position, target, 5f * deltaTime);
            followCamera.transform.LookAt(transform.position + Vector3.up);
        }
    }
}
