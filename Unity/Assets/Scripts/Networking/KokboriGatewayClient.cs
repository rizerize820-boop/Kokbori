using System;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

/// <summary>
/// Minimal TCP transport for a dedicated KOKBORI gateway.
/// This is NOT an SA-MP/RakNet client and must not connect to the stock
/// SA-MP game port unless a compatible gateway is installed there.
/// Wire format: UTF-8 JSON, one message per newline.
/// </summary>
public sealed class KokboriGatewayClient : MonoBehaviour
{
    [SerializeField] private string host = "127.0.0.1";
    [SerializeField] private int port = 7778;

    private TcpClient client;
    private StreamWriter writer;
    private CancellationTokenSource cancellation;

    public event Action<string> MessageReceived;
    public event Action<string> ConnectionError;

    public async Task ConnectAsync()
    {
        if (client != null && client.Connected) return;

        cancellation = new CancellationTokenSource();
        client = new TcpClient();
        try
        {
            await client.ConnectAsync(host, port);
            writer = new StreamWriter(client.GetStream(), new UTF8Encoding(false))
            {
                AutoFlush = true,
                NewLine = "\n"
            };

            await SendJsonAsync("{\"v\":1,\"type\":\"hello\",\"client\":\"kokbori-unity\"}");
            _ = ReadLoopAsync(cancellation.Token);
        }
        catch (Exception ex)
        {
            ConnectionError?.Invoke(ex.Message);
            Disconnect();
        }
    }

    public async Task SendJsonAsync(string json)
    {
        if (writer == null || client == null || !client.Connected)
            throw new InvalidOperationException("Not connected to KOKBORI gateway.");

        if (string.IsNullOrWhiteSpace(json) || json.Length > 4096)
            throw new ArgumentException("Message is empty or exceeds 4096 characters.");

        await writer.WriteLineAsync(json);
    }

    private async Task ReadLoopAsync(CancellationToken token)
    {
        try
        {
            using var reader = new StreamReader(client.GetStream(), Encoding.UTF8);
            while (!token.IsCancellationRequested && client.Connected)
            {
                var line = await reader.ReadLineAsync();
                if (line == null) break;
                if (line.Length > 8192) throw new InvalidDataException("Server message too large.");
                MessageReceived?.Invoke(line);
            }
        }
        catch (Exception ex)
        {
            if (!token.IsCancellationRequested)
                ConnectionError?.Invoke(ex.Message);
        }
        finally
        {
            Disconnect();
        }
    }

    public void Disconnect()
    {
        cancellation?.Cancel();
        writer?.Dispose();
        client?.Close();
        writer = null;
        client = null;
    }

    private void OnDestroy() => Disconnect();
}
