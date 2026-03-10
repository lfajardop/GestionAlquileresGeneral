using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Infraestructura.Seguridad
{
    public class Criptografia
    {
        private static string key = "bjr2017@";

        /// <summary>
        /// Encripta el texto
        /// </summary>
        /// <param name="texto">Texto a encriptar</param>
        /// <returns></returns>
        public static string Encriptar(string texto)
        {
            return Encriptar(texto, key);
        }

        /// <summary>
        /// Encripta el texto, con la key indicada
        /// </summary>
        /// <param name="texto">Texto a encriptar</param>
        /// <param name="key">Key de encriptación</param>
        /// <returns></returns>
        public static string Encriptar(string texto, string key)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(texto))
                {
                    //se utilizan las clases de encriptación provistas por el Framework Algoritmo MD5
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();

                    //Algoritmo 3DAS
                    TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();

                    //array de bytes donde guardaremos el texto que vamos a encriptar
                    byte[] arrayCadena = Encoding.UTF8.GetBytes(texto);

                    //array de bytes donde guardaremos la llave
                    byte[] arrayKey = hashmd5.ComputeHash(Encoding.UTF8.GetBytes(key));

                    hashmd5.Clear();

                    tdes.Key = arrayKey;
                    tdes.Mode = CipherMode.ECB;
                    tdes.Padding = PaddingMode.PKCS7;

                    //array de bytes donde se guarda la cadena encriptada
                    //se empieza con la transformación de la cadena
                    byte[] arrayCadenaEncriptada = tdes.CreateEncryptor().TransformFinalBlock(arrayCadena, 0, arrayCadena.Length);
                    tdes.Clear();
                    texto = Convert.ToBase64String(arrayCadenaEncriptada, 0, arrayCadenaEncriptada.Length);
                }
            }
            catch (Exception)
            {
                throw;
            }
            return texto;
        }

        public static string Desencriptar(object p)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Desencripta el texto
        /// </summary>
        /// <param name="texto">Texto a desencriptar</param>
        /// <returns></returns>
        public static string Desencriptar(string texto)
        {
            return Desencriptar(texto, key);
        }

        /// <summary>
        /// Desencripta el texto, con la key indicada
        /// </summary>
        /// <param name="text">Texto a desencriptar</param>
        /// <param name="key">Key de desencriptación</param>
        /// <returns></returns>
        public static string Desencriptar(string text, string key)
        {
            try
            {
                if (!string.IsNullOrWhiteSpace(text))
                {
                    //se utilizan las clases de encriptación provistas por el Framework Algoritmo MD5
                    MD5CryptoServiceProvider hashmd5 = new MD5CryptoServiceProvider();

                    //Algoritmo 3DAS
                    TripleDESCryptoServiceProvider tdes = new TripleDESCryptoServiceProvider();

                    //array de bytes donde guardaremos el texto que vamos a desencriptar
                    byte[] arrayCadena = Convert.FromBase64String(text);

                    //array de bytes donde guardaremos la llave
                    byte[] arrayKey = hashmd5.ComputeHash(Encoding.UTF8.GetBytes(key));
                    hashmd5.Clear();

                    tdes.Key = arrayKey;
                    tdes.Mode = CipherMode.ECB;
                    tdes.Padding = PaddingMode.PKCS7;

                    //array de bytes donde se guarda la cadena desencriptada
                    //se empieza con la transformación de la cadena
                    byte[] arrayCadenaDesencriptada = tdes.CreateDecryptor().TransformFinalBlock(arrayCadena, 0, arrayCadena.Length);
                    tdes.Clear();
                    text = Encoding.UTF8.GetString(arrayCadenaDesencriptada);
                }
            }
            catch (Exception)
            {
                throw;
            }
            return text;
        }
    }
}

