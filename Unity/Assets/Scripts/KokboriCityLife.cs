using UnityEngine;

/// <summary>Lightweight ambient city life for the KOKBORI greybox prototype.</summary>
public sealed class KokboriCityLife : MonoBehaviour
{
    private Transform player;
    private GUIStyle promptStyle;
    private bool shopNearby;
    private string notice = "";

    public static KokboriCityLife Create(Transform playerTransform)
    {
        var root = new GameObject("KOKBORI City Life");
        var life = root.AddComponent<KokboriCityLife>();
        life.player = playerTransform;
        life.BuildPedestrians();
        life.BuildBus();
        life.BuildShop();
        return life;
    }

    public void InteractShop()
    {
        if (shopNearby) notice = "Магазин: ассортимент скоро появится.";
    }

    private void BuildPedestrians()
    {
        Vector3[] starts =
        {
            new Vector3(-7, 0, -18), new Vector3(7, 0, -8),
            new Vector3(-8, 0, 15), new Vector3(8, 0, 29),
            new Vector3(-12, 0, 36), new Vector3(12, 0, -36),
            new Vector3(-18, 0, 4), new Vector3(18, 0, 18)
        };
        for (int i = 0; i < starts.Length; i++)
        {
            var npc = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            npc.name = "City Pedestrian " + (i + 1);
            npc.transform.position = starts[i] + Vector3.up;
            npc.transform.localScale = new Vector3(0.72f, 0.95f, 0.72f);
            npc.GetComponent<Renderer>().material = MaterialFor(
                i % 3 == 0 ? new Color(0.55f, 0.25f, 0.18f) :
                i % 3 == 1 ? new Color(0.18f, 0.32f, 0.55f) : new Color(0.28f, 0.38f, 0.25f));
            Object.Destroy(npc.GetComponent<CapsuleCollider>());
            var walker = npc.AddComponent<KokboriPedestrian>();
            Vector3 a = starts[i];
            Vector3 b = a + new Vector3(i % 2 == 0 ? 5f : -5f, 0, i % 2 == 0 ? 4f : -4f);
            walker.SetRoute(a, b, 1.05f + (i % 3) * 0.18f);
        }
    }

    private void BuildBus()
    {
        var bus = GameObject.CreatePrimitive(PrimitiveType.Cube);
        bus.name = "Astana City Bus";
        bus.transform.position = new Vector3(-13, 1.35f, 18);
        bus.transform.localScale = new Vector3(2.4f, 2.7f, 7.5f);
        bus.GetComponent<Renderer>().material = MaterialFor(new Color(0.12f, 0.42f, 0.32f));
        var route = bus.AddComponent<KokboriBusRoute>();
        route.SetPath(new Vector3(-13, 1.35f, 18), new Vector3(-13, 1.35f, 38),
            new Vector3(13, 1.35f, 38), new Vector3(13, 1.35f, 18));
        CreatePart("Bus Window Band", bus.transform, new Vector3(0, 0.28f, 0),
            new Vector3(1.02f, 0.28f, 0.92f), new Color(0.12f, 0.25f, 0.32f));
        CreatePart("Bus Destination Panel", bus.transform, new Vector3(0, 0.39f, -0.47f),
            new Vector3(0.58f, 0.12f, 0.03f), new Color(0.92f, 0.78f, 0.28f));
    }

    private void BuildShop()
    {
        var shop = GameObject.CreatePrimitive(PrimitiveType.Cube);
        shop.name = "Interactive Mini Market";
        shop.transform.position = new Vector3(-19, 1.5f, 12);
        shop.transform.localScale = new Vector3(5, 3, 4);
        shop.GetComponent<Renderer>().material = MaterialFor(new Color(0.55f, 0.48f, 0.34f));
        var trigger = shop.GetComponent<BoxCollider>();
        trigger.isTrigger = true;
        shop.AddComponent<KokboriShopTrigger>().Initialize(this);
        CreatePart("Shop Sign", shop.transform, new Vector3(0, 0.34f, -0.51f),
            new Vector3(0.85f, 0.16f, 0.04f), new Color(0.12f, 0.35f, 0.22f));
    }

    private void Update()
    {
        if (player == null) return;
        shopNearby = Vector3.Distance(player.position, new Vector3(-19, 1, 12)) < 4.5f;
        if (!shopNearby) notice = "";
    }

    private void OnGUI()
    {
        if (!shopNearby && string.IsNullOrEmpty(notice)) return;
        if (promptStyle == null)
        {
            promptStyle = new GUIStyle(GUI.skin.box);
            promptStyle.fontSize = 18;
            promptStyle.alignment = TextAnchor.MiddleCenter;
            promptStyle.normal.textColor = Color.white;
        }
        string message = string.IsNullOrEmpty(notice) ? "МАГАЗИН  •  нажми кнопку SHOP" : notice;
        GUI.Box(new Rect(Screen.width * 0.5f - 190, Screen.height - 115, 380, 48), message, promptStyle);
    }

    private static void CreatePart(string name, Transform parent, Vector3 localPosition,
        Vector3 localScale, Color color)
    {
        var part = GameObject.CreatePrimitive(PrimitiveType.Cube);
        part.name = name;
        part.transform.SetParent(parent, false);
        part.transform.localPosition = localPosition;
        part.transform.localScale = localScale;
        Object.Destroy(part.GetComponent<Collider>());
        part.GetComponent<Renderer>().material = MaterialFor(color);
    }

    private static Material MaterialFor(Color color)
    {
        Shader shader = Shader.Find("Universal Render Pipeline/Lit");
        if (shader == null) shader = Shader.Find("Standard");
        var material = new Material(shader);
        material.color = color;
        return material;
    }

    public sealed class KokboriPedestrian : MonoBehaviour
    {
        private Vector3 pointA, pointB, target;
        private float speed;
        public void SetRoute(Vector3 a, Vector3 b, float walkSpeed)
        {
            pointA = a; pointB = b; target = b; speed = walkSpeed;
        }
        private void Update()
        {
            Vector3 direction = target - transform.position;
            direction.y = 0;
            if (direction.magnitude < 0.35f)
            {
                target = target == pointA ? pointB : pointA;
                return;
            }
            transform.position += direction.normalized * speed * Time.deltaTime;
            transform.rotation = Quaternion.Slerp(transform.rotation,
                Quaternion.LookRotation(direction.normalized), 7f * Time.deltaTime);
        }
    }

    public sealed class KokboriBusRoute : MonoBehaviour
    {
        private Vector3[] path;
        private int nextPoint;
        private float speed = 4f;
        public void SetPath(params Vector3[] points) { path = points; nextPoint = 1; }
        private void Update()
        {
            if (path == null || path.Length < 2) return;
            Vector3 direction = path[nextPoint] - transform.position;
            if (direction.magnitude < 0.6f)
            {
                nextPoint = (nextPoint + 1) % path.Length;
                return;
            }
            Vector3 flat = direction; flat.y = 0;
            transform.position += flat.normalized * speed * Time.deltaTime;
            if (flat.sqrMagnitude > 0.01f)
                transform.rotation = Quaternion.Slerp(transform.rotation,
                    Quaternion.LookRotation(flat), 3f * Time.deltaTime);
        }
    }

    public sealed class KokboriShopTrigger : MonoBehaviour
    {
        private KokboriCityLife owner;
        public void Initialize(KokboriCityLife cityLife) => owner = cityLife;
        private void OnTriggerEnter(Collider other)
        {
            if (other.CompareTag("Player") && owner != null) owner.shopNearby = true;
        }
    }
}
