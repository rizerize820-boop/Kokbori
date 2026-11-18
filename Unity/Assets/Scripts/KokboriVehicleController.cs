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
        // Custom low-poly body mesh with tapered bonnet and rear quarter.
        Vector3[] bodyVertices =
        {
            new Vector3(-0.92f,0.42f,-2.05f), new Vector3(0.92f,0.42f,-2.05f),
            new Vector3(-1.02f,0.42f,1.55f), new Vector3(1.02f,0.42f,1.55f),
            new Vector3(-0.82f,1.02f,-1.45f), new Vector3(0.82f,1.02f,-1.45f),
            new Vector3(-0.88f,0.92f,1.62f), new Vector3(0.88f,0.92f,1.62f),
            new Vector3(-0.72f,0.92f,2.02f), new Vector3(0.72f,0.92f,2.02f)
        };
        int[] bodyTriangles = {
            0,2,1, 1,2,3, 0,4,2, 2,4,6, 1,3,5, 3,7,5,
            4,5,6, 5,7,6, 2,6,3, 3,6,7, 4,8,5, 5,8,9,
            6,5,7, 7,5,9, 6,8,7, 7,8,9
        };
        MakeMeshPart("Sculpted Sedan Body", bodyVertices, bodyTriangles, new Color(0.06f,0.22f,0.48f));

        MakePart("Roof", new Vector3(0,1.55f,-0.12f), new Vector3(1.48f,0.16f,1.48f), new Color(0.055f,0.18f,0.36f));
        MakePart("Front Windshield", new Vector3(0,1.24f,0.95f), new Vector3(1.42f,0.62f,0.07f), new Color(0.18f,0.38f,0.48f));
        MakePart("Rear Windshield", new Vector3(0,1.24f,-1.08f), new Vector3(1.42f,0.58f,0.07f), new Color(0.18f,0.38f,0.48f));
        MakePart("Left Side Glass", new Vector3(-0.755f,1.28f,-0.12f), new Vector3(0.055f,0.52f,1.32f), new Color(0.16f,0.34f,0.43f));
        MakePart("Right Side Glass", new Vector3(0.755f,1.28f,-0.12f), new Vector3(0.055f,0.52f,1.32f), new Color(0.16f,0.34f,0.43f));
        MakePart("Front Bumper", new Vector3(0,0.48f,2.02f), new Vector3(1.88f,0.2f,0.16f), new Color(0.12f,0.13f,0.15f));
        MakePart("Rear Bumper", new Vector3(0,0.48f,-2.03f), new Vector3(1.88f,0.2f,0.16f), new Color(0.12f,0.13f,0.15f));
        MakePart("Front Grille", new Vector3(0,0.7f,2.035f), new Vector3(0.72f,0.22f,0.035f), new Color(0.025f,0.03f,0.04f));
        MakePart("Left Headlight", new Vector3(-0.67f,0.82f,1.99f), new Vector3(0.42f,0.2f,0.06f), new Color(0.95f,0.9f,0.68f));
        MakePart("Right Headlight", new Vector3(0.67f,0.82f,1.99f), new Vector3(0.42f,0.2f,0.06f), new Color(0.95f,0.9f,0.68f));
        MakePart("Left Tail Light", new Vector3(-0.68f,0.78f,-2.04f), new Vector3(0.38f,0.2f,0.06f), new Color(0.72f,0.06f,0.04f));
        MakePart("Right Tail Light", new Vector3(0.68f,0.78f,-2.04f), new Vector3(0.38f,0.2f,0.06f), new Color(0.72f,0.06f,0.04f));

        for (int side = -1; side <= 1; side += 2)
        for (int axle = -1; axle <= 1; axle += 2)
        {
            var wheel = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            wheel.name = "Rubber Tyre";
            wheel.transform.SetParent(transform, false);
            wheel.transform.localPosition = new Vector3(side * 0.98f, 0.43f, axle * 1.32f);
            wheel.transform.localRotation = Quaternion.Euler(0, 0, 90);
            wheel.transform.localScale = new Vector3(0.76f, 0.19f, 0.76f);
            wheel.GetComponent<Renderer>().material = MakeMaterial(new Color(0.025f,0.027f,0.03f));
            var hub = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            hub.name = "Alloy Wheel";
            hub.transform.SetParent(wheel.transform, false);
            hub.transform.localPosition = new Vector3(0,0.56f,0);
            hub.transform.localRotation = Quaternion.identity;
            hub.transform.localScale = new Vector3(0.55f,0.18f,0.55f);
            hub.GetComponent<Renderer>().material = MakeMaterial(new Color(0.48f,0.5f,0.53f));
        }
        MakePart("Left Mirror", new Vector3(-1.02f,1.24f,0.72f), new Vector3(0.22f,0.16f,0.32f), new Color(0.04f,0.06f,0.08f));
        MakePart("Right Mirror", new Vector3(1.02f,1.24f,0.72f), new Vector3(0.22f,0.16f,0.32f), new Color(0.04f,0.06f,0.08f));
        MakePart("License Plate", new Vector3(0,0.58f,2.12f), new Vector3(0.55f,0.16f,0.025f), Color.white);
    }

    private void MakeMeshPart(string partName, Vector3[] vertices, int[] triangles, Color color)
    {
        var part = new GameObject(partName);
        part.transform.SetParent(transform, false);
        var mesh = new Mesh();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
        mesh.RecalculateBounds();
        var filter = part.AddComponent<MeshFilter>();
        filter.sharedMesh = mesh;
        var renderer = part.AddComponent<MeshRenderer>();
        renderer.material = MakeMaterial(color);
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
